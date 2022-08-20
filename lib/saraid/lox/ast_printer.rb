module Saraid
  module Lox
    class AstPrinter
      def print(expr)
        expr.accept(self)
      end

      def visitBinaryExpr(expr)
        parenthesize(expr.operator.lexeme, expr.left, expr.right)
      end

      def visitGroupingExpr(expr)
        parenthesize('group', expr.expression)
      end

      def visitLiteralExpr(expr)
        return nil if expr.nil?
        expr.value.to_s
      end

      def visitUnaryExpr(expr)
        parenthesize(expr.operator.lexeme, expr.right)
      end

      private def parenthesize(name, *exprs)
        [name, *exprs.map { _1.accept(self) }]
          .join(' ')
          .then { "(#{_1})" }
      end

      def self.main(args = [])
        expression = Expr::Binary.new(
          Expr::Unary.new(
            Token.new(:minus, '-', nil, 1),
            Expr::Literal.new(123)
          ),
          Token.new(:star, '*', nil, 1),
          Expr::Grouping.new(Expr::Literal.new(45.67))
        )

        puts new.print(expression)
      end
    end
  end
end
