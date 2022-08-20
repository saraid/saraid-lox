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
        equality
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
        return @current += 1 unless is_at_end?
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
        primary
      end

      private def primary
        return Expr::Literal.new(false) if match(:false)
        return Expr::Literal.new(true) if match(:true)
        return Expr::Literal.new(nil) if match(:nil)

        return Expr::Literal.new(previous.literal) if match(:number, :string)

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
        begin
          expression
        rescue Error
          nil
        end
      end
    end
  end
end
