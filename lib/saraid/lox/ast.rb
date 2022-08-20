module Saraid
  module Lox
    generate_ast :Expr, {
      Binary: %i( left operator right ),
      Grouping: %i( expression ),
      Literal: %i( value ),
      Unary: %i( operator right ),
      Variable: %i( name ),
    }

    generate_ast :Stmt, {
      Expression: %i( expression ),
      Print: %i( expression ),
      Var: %i( name initializer ),
    }
  end
end
