module Saraid
  module Lox
    generate_ast :Expr, {
      Binary: %i( left operator right ),
      Grouping: %i( expression ),
      Literal: %i( value ),
      Unary: %i( operator right ),
      Variable: %i( name ),
      Assign: %i( name value ),
    }

    generate_ast :Stmt, {
      Expression: %i( expression ),
      Print: %i( expression ),
      Var: %i( name initializer ),
      Block: %i( statements ),
      If: %i( condition thenBranch elseBranch ),
    }
  end
end
