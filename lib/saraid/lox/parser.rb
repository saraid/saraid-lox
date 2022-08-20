module Saraid
  module Lox
    class Parser
      class Error < Lox::Error; end

      def initialize(tokens)
        @tokens = tokens
        @current = 0
      end
      attr_reader :tokens
      attr_reader :current

      private def expression
        assignment
      end

      private def assignment
        expr = or_expr

        if match(:equal)
          equals = previous
          value = assignment

          if Expr::Variable === expr
            name = expr.name
            return Expr::Assign.new(name, value)
          elsif Expr::Get === expr
            return Expr::Set.new(expr.object, expr.name, value)
          end

          error(equals, "Invalid assignment target.")
        end

        expr
      end

      private def or_expr
        expr = and_expr
        expr = Expr::Logical.new(expr, previous, and_expr) while match(:or)
        expr
      end

      private def and_expr
        expr = equality
        expr = Expr::Logical.new(expr, previous, equality) while match(:and)
        expr
      end

      private def equality
        expr = comparison

        while match(:bang_equal, :equal_equal)
          operator = previous
          right = comparison
          expr = Expr::Binary.new(expr, operator, right)
        end

        expr
      end

      private def match(*types)
        return false unless types.any? { check(_1) }
        advance
        true
      end

      private def check(type)
        return false if is_at_end?
        peek.type == type
      end

      private def advance
        @current += 1 unless is_at_end?
        previous
      end

      private def is_at_end?
        peek.type == :eof
      end

      private def peek
        tokens[current]
      end

      private def previous
        tokens[current - 1]
      end

      private def comparison
        expr = term

        while match(:greater, :greater_equal, :less, :less_equal)
          expr = Expr::Binary.new(expr, previous, term) 
        end

        expr
      end

      private def term
        expr = factor
        expr = Expr::Binary.new(expr, previous, factor) while match(:minus, :plus)
        expr
      end

      private def factor
        expr = unary
        expr = Expr::Binary.new(expr, previous, unary) while match(:slash, :star)
        expr
      end

      private def unary
        return Expr::Unary.new(previous, unary) if match(:bang, :minus)
        call
      end

      private def call
        expr = primary
        loop do
          if match(:left_paren) then expr = finishCall(expr)
          elsif match(:dot)
            name = consume(:identifier, "Expect property name after '.'.")
            expr = Expr::Get.new(expr, name)
          else break
          end
        end
        expr
      end

      private def finishCall(callee)
        arguments = []
        unless check(:right_paren)
          loop do
            error(peek, "Can't have more than 255 arguments.") if arguments.size >= 255
            arguments << expression
            break unless match(:comma)
          end
        end

        paren = consume(:right_paren, "Expect ')' after arguments.")
        Expr::Call.new(callee, paren, arguments)
      end

      private def primary
        return Expr::Literal.new(false) if match(:false)
        return Expr::Literal.new(true) if match(:true)
        return Expr::Literal.new(nil) if match(:nil)

        return Expr::Literal.new(previous.literal) if match(:number, :string)

        return Expr::This.new(previous) if match(:this)
        return Expr::Variable.new(previous) if match(:identifier)

        if match(:left_paren)
          expr = expression
          consume :right_paren, "Expect ')' after expression."
          Expr::Grouping.new(expr)
        end

        raise error(peek, 'Expect expression.')
      end

      private def consume(type, message)
        return advance if check(type)

        raise error(peek, message)
      end

      private def error(token, message)
        Lox.error(token, message)
        Error.new
      end

      private def synchronize
        advance

        until is_at_end?
          return if previous.type == :semicolon
          return if %i( class fun var for if while print return ).include?(peek.type)

          advance
        end
      end

      def parse
        statements = []
        statements << declaration until is_at_end?
        statements
      end

      private def declaration
        begin
          return classDeclaration if match(:class)
          return function('function') if match(:fun)
          return varDeclaration if match(:var)
          statement
        rescue Error
          synchronize
          nil
        end
      end

      private def classDeclaration
        name = consume(:identifier, "Expect class name.")
        consume(:left_brace, "Expect '{' before class body.")
        methods = []
        methods << function("method") while !check(:right_brace) && !is_at_end?

        consume(:right_brace, "Expect '}' after class body.");

        Stmt::Class.new(name, methods)
      end

      private def function(kind)
        name = consume(:identifier, "Expect #{kind} name.")
        consume(:left_paren, "Expect '(' after #{kind} name.")
        parameters = []
        unless check(:right_paren)
          loop do
            error(peek, "Can't have more than 255 parameters.") if parameters.size >= 255
            parameters << consume(:identifier, "Expect parameter name.")
            break unless match(:comma)
          end
        end
        consume(:right_paren, "Expect ')' after parameters.")

        consume(:left_brace, "Expect '{' before #{kind} body.");
        body = block
        Stmt::Function.new(name, parameters, body)
      end

      private def varDeclaration
        name = consume(:identifier, "Expect variable name.")

        initializer = expression if match(:equal)

        consume(:semicolon, "Expect ';' after variable declaration.");
        Stmt::Var.new(name, initializer)
      end

      private def statement
        return forStatement if match(:for)
        return ifStatement if match(:if)
        return printStatement if match(:print)
        return returnStatement if match(:return)
        return whileStatement if match(:while)
        return Stmt::Block.new(block) if match(:left_brace)
        expressionStatement
      end

      private def returnStatement
        keyword = previous
        value = expression unless check(:semicolon)
        consume(:semicolon, "Expect ';' after return value.")
        Stmt::Return.new(keyword, value)
      end

      private def forStatement
        consume(:left_paren, "Expect '(' after 'for'.");

        initializer =
          case
          when match(:semicolon) then nil
          when match(:var) then varDeclaration
          else expressionStatement
          end

        condition = expression unless check(:semicolon)
        consume(:semicolon, "Expect ';' after loop condition.");

        increment = expression unless check(:right_paren)
        consume(:right_paren, "Expect ')' after for clauses.");
        body = statement

        body = Stmt::Block.new([body, Stmt::Expression.new(increment)]) if increment

        condition ||= Expr::Literal.new(true)
        body = Stmt::While.new(condition, body)
        body = Stmt::Block.new([initializer, body]) if initializer

        body
      end

      private def whileStatement
        consume(:left_paren, "Expect '(' after 'while'.");
        condition = expression
        consume(:right_paren, "Expect ')' after condition.");
        body = statement

        Stmt::While.new(condition, body)
      end

      private def ifStatement
        consume(:left_paren, "Expect '(' after 'if'.")
        condition = expression;
        consume(:right_paren, "Expect ')' after if condition.")

        thenBranch = statement
        elseBranch = statement if match(:else)

        Stmt::If.new(condition, thenBranch, elseBranch)
      end

      private def block
        statements = []
        statements << declaration while !check(:right_brace) && !is_at_end?
        consume(:right_brace, "Expect '}' after block.");
        statements
      end

      private def printStatement
        value = expression
        consume(:semicolon, "Expect ';' after value.");
        Stmt::Print.new(value)
      end

      private def expressionStatement
        expr = expression
        consume(:semicolon, "Expect ';' after expression.");
        Stmt::Expression.new(expr)
      end
    end
  end
end
