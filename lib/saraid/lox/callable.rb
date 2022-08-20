module Saraid
  module Lox
    class Callable
    end

    class Function < Callable
      def initialize(declaration)
        @declaration = declaration
      end
      attr_reader :declaration

      def arity
        declaration.params.size
      end

      def call(interpreter, arguments)
        environment = interpreter.globals
        declaration.params.each.with_index do |param, i|
          environment.define(param.lexeme, arguments[i])
        end

        interpreter.executeBlock(declaration.body, environment)
        nil
      end

      def to_s
        "<fn #{declaration.name.lexeme}>"
      end
    end
  end
end
