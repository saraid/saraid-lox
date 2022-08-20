module Saraid
  module Lox
    Visitor = Module.new

    def self.generate_ast(superclass_name, definitions)
      superclass = const_set(superclass_name, Class.new)
      definitions.each do |subclass, parameters|
        visitorMethod = :"visit#{subclass}#{superclass_name}"
        superclass.const_set(subclass, Class.new(superclass) do
          define_method(:initialize) do |*arguments|
            parameters.each.with_index do |param, i|
              instance_variable_set(:"@#{param}", arguments[i])
            end
          end
          attr_reader *parameters

          define_method(:accept) do |visitor|
            visitor.send(visitorMethod, self)
          end
        end)
        Visitor.define_method(visitorMethod) { |*args| }
      end
    end

    generate_ast :Expr, {
      Binary: %i( left operator right ),
      Grouping: %i( expression ),
      Literal: %i( value ),
      Unary: %i( operator right ),
      Variable: %i( name ),
      Assign: %i( name value ),
      Logical: %i( left operator right ),
      Call: %i( callee paren arguments ),
      Get: %i( object name ),
      Set: %i( object name value ),
      This: %i( keyword ),
      Super: %i( keyword method ),
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
      Class: %i( name superclass methods ),
    }
  end
end
