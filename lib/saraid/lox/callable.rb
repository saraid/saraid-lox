module Saraid
  module Lox
    class Callable
    end

    class Function < Callable
      def initialize(declaration)
        @declaration = declaration
        declaration.body.each { puts _1.inspect }
      end
      attr_reader :declaration

      def arity
        declaration.params.size
      end

      def call(interpreter, arguments)
        environment = Environment.new(interpreter.globals)
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
