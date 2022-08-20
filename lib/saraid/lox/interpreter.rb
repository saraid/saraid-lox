module Saraid
  module Lox
    class Interpreter
      class RuntimeError < Lox::Error
        def initialize(token, message)
          super(message)
          @token = token
        end
        attr_reader :token
      end

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
          if (Float === left && Float === right)
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
        raise RuntimeError.new(operator, 'Operand must be a number.') unless Float === operand
      end

      private def check_number_operands!(operator, left, right)
        valid = [left, right].all? { Float === _1 }
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
        when Float then object.to_s.tap { _1.sub!(/\.0$/, '') }
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
    end
  end
end
