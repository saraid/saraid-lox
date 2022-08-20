module Saraid
  module Lox
    Visitor = Module.new

    generate_ast :Expr, {
      Binary: %i( left operator right ),
      Grouping: %i( expression ),
      Literal: %i( value ),
      Unary: %i( operator right ),
      Variable: %i( name ),
      Assign: %i( name value ),
      Logical: %i( left operator right ),
      Call: %i( callee paren arguments ),
    }

    generate_ast :Stmt, {
      Expression: %i( expression ),
      Print: %i( expression ),
      Var: %i( name initializer ),
      Block: %i( statements ),
      If: %i( condition thenBranch elseBranch ),
      While: %i( condition body ),
      Function: %i( name params body ),
      Return: %i( keyword value ),
      Class: %i( name methods ),
    }
  end
end
