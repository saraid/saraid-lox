module Saraid
  module Lox
    generate_ast :Expr, {
      Binary: %i( left operator right ),
      Grouping: %i( expression ),
      Literal: %i( value ),
      Unary: %i( operator right ),
    }

    generate_ast :Stmt, {
      Expression: %i( expression ),
      Print: %i( expression ),
    }
  end
end
