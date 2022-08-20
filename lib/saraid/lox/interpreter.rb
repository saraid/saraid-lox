module Saraid
  module Lox
    class Interpreter
      class Return < StandardError
        def initialize(value)
          @value = value
        end
        attr_reader :value
      end

      def initialize
        @globals = Environment.new
        @locals = {}
        @environment = @globals

        @globals.define('clock', Class.new do
          def arity
            0
          end

          def call(interpreter, arguments)
            Time.now
          end

          def to_s
            '<native fn>'
          end
        end)
      end
      attr_reader :globals

      def visitLiteralExpr(expr)
        expr.value
      end

      def visitGroupingExpr(expr)
        evaluate(expr.expression)
      end

      private def evaluate(expr)
        expr.accept(self)
      end

      def visitUnaryExpr(expr)
        right = evaluate expr.right
        case expr.operator.type
        when :bang then !is_truthy?(right)
        when :minus
          check_number_operand!(expr.operator, right)
          -right
        end
      end

      private def is_truthy?(object)
        return false if object.nil?
        !!object # FIXME test
      end

      def visitBinaryExpr(expr)
        left = evaluate expr.left
        right = evaluate expr.right

        case expr.operator.type
        when :minus 
          check_number_operands!(expr.operator, left, right)
          left - right
        when :slash 
          check_number_operands!(expr.operator, left, right)
          left / right
        when :star 
          check_number_operands!(expr.operator, left, right)
          left * right
        when :plus
          if (Numeric === left && Numeric === right)
            check_number_operands!(expr.operator, left, right)
            left + right
          elsif (String === left && String === right)
            left + right
          else
            raise RuntimeError.new(operator, 'Operands must be two numbers or two strings.')
          end
        when :greater 
          check_number_operands!(expr.operator, left, right)
          left > right
        when :less 
          check_number_operands!(expr.operator, left, right)
          left < right
        when :greater_equal 
          check_number_operands!(expr.operator, left, right)
          left >= right
        when :less_equal 
          check_number_operands!(expr.operator, left, right)
          left <= right
        when :bang_equal then !is_equal?(left, right)
        when :equal_equal then is_equal?(left, right)
        end
      end

      private def is_equal?(a, b)
        return true if a.nil? && b.nil?
        return false if a.nil?

        a == b
      end

      private def check_number_operand!(operator, operand)
        raise RuntimeError.new(operator, 'Operand must be a number.') unless Numeric === operand
      end

      private def check_number_operands!(operator, left, right)
        valid = [left, right].all? { Numeric === _1 }
        raise RuntimeError.new(operator, 'Operands must be numbers.') unless valid
      end

      def interpret(expr_or_stmts)
        begin
          case expr_or_stmts
          when Array
            stmts = expr_or_stmts
            stmts.each { execute(_1) }
          else
            value = evaluate expr_or_stmts
            puts stringify(value)
          end
        rescue RuntimeError => e
          Lox.runtime_error(e)
        end
      end

      private def stringify(object)
        case object
        when NilClass then 'nil'
        when Numeric then object.to_s.tap { _1.sub!(/\.0$/, '') }
        else object.to_s
        end
      end

      def visitExpressionStmt(stmt)
        evaluate(stmt.expression)
        nil
      end

      def visitPrintStmt(stmt)
        puts stringify evaluate stmt.expression
        nil
      end

      private def execute(stmt)
        stmt.accept(self)
      end

      private def visitVarStmt(stmt)
        value = stmt.initializer&.then { evaluate _1 }

        @environment.define(stmt.name.lexeme, value)
        nil
      end

      private def visitVariableExpr(expr)
        lookUpVariable(expr.name, expr)
      end

      private def lookUpVariable(name, expr)
        distance = @locals[expr]
        if distance
          @environment.getAt(distance, name.lexeme)
        else
          globals.get(name)
        end
      end

      private def visitAssignExpr(expr)
        value = evaluate expr.value

        distance = @locals[expr]
        if distance then @environment.assignAt(distance, expr.name, value)
        else globals.assign(expr.name, value)
        end
        value
      end

      private def visitBlockStmt(stmt)
        executeBlock(stmt.statements, Environment.new(@environment))
        nil
      end

      def executeBlock(statements, environment)
        previous = @environment
        
        begin
          @environment = environment
          statements.each { execute _1 }
        ensure
          @environment = previous
        end
        nil
      end

      def visitIfStmt(stmt)
        if is_truthy?(evaluate(stmt.condition))
          execute(stmt.thenBranch)
        elsif stmt.elseBranch
          execute(stmt.elseBranch)
        end
        nil
      end

      def visitLogicalExpr(expr)
        left = evaluate expr.left

        case expr.operator.type
        when :or then return left if is_truthy?(left)
        when :and then return left unless is_truthy?(left)
        end

        evaluate expr.right
      end

      def visitWhileStmt(stmt)
        execute(stmt.body) while is_truthy?(evaluate stmt.condition)
        nil
      end

      def visitCallExpr(expr)
        callee = evaluate expr.callee
        arguments = expr.arguments.map { evaluate _1 }

        unless callee.respond_to?(:call)
          raise RuntimeError.new(expr.paren, "Can only call functions and classes.")
        end

        if arguments.size != callee.arity
          raise RuntimeError.new(expr.paren,
                                 "Expected #{callee.arity} arguments but got #{arguments.size}")
        end
        callee.call(self, arguments)
      end

      def visitFunctionStmt(stmt)
        @environment.define(stmt.name.lexeme, LoxFunction.new(stmt, @environment, false))
        nil
      end

      def visitReturnStmt(stmt)
        value = evaluate(stmt.value) if stmt.value
        raise Return.new(value)
      end

      def resolve(expr, depth)
        @locals[expr] = depth
      end

      def visitClassStmt(stmt)
        superclass =
          stmt.superclass
            &.then { evaluate _1 }
            &.tap do
              unless LoxClass === _1
                raise RuntimeError.new(stmt.superclass.name, "Superclass must be a class.");
              end
            end

        @environment.define(stmt.name.lexeme, nil)
        methods = stmt.methods.each.with_object({}) do |meth, collection|
          collection[meth.name.lexeme] = LoxFunction.new(meth, @environment, meth.name.lexeme == 'init')
        end
        @environment.assign(stmt.name, LoxClass.new(stmt.name.lexeme, superclass, methods))
        nil
      end

      def visitGetExpr(expr)
        object = evaluate(expr.object)
        return object.get(expr.name) if LoxInstance === object

        raise RuntimeError.new(expr.name, "Only instances have properties.")
      end

      def visitSetExpr(expr)
        object = evaluate(expr.object)
        raise RuntimeError.new(expr.name, "Only instances have properties.") unless LoxInstance === object
        value = evaluate(expr.value)
        object.set(expr.name, value)
        value
      end

      def visitThisExpr(expr)
        #require 'byebug'; byebug
        lookUpVariable(expr.keyword, expr)
      end
    end
  end
end
