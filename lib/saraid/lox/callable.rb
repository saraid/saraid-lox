module Saraid
  module Lox
    class Callable
    end

    class LoxFunction < Callable
      def initialize(declaration, closure)
        @declaration = declaration
        @closure = closure
      end
      attr_reader :declaration, :closure

      def arity
        declaration.params.size
      end

      def call(interpreter, arguments)
        environment = Environment.new(closure)
        declaration.params.each.with_index do |param, i|
          environment.define(param.lexeme, arguments[i])
        end

        begin
          interpreter.executeBlock(declaration.body, environment)
        rescue Interpreter::Return => returnStmt
          returnStmt.value
        end
      end

      def to_s
        "<fn #{declaration.name.lexeme}>"
      end
    end
  end
end
