module Saraid
  module Lox
    class LoxCallable
    end

    class LoxFunction < LoxCallable
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

    class LoxClass < LoxCallable
      def initialize(name)
        @name = name
      end
      attr_reader :name

      def arity
        0
      end

      def call(interpreter, arguments)
        LoxInstance.new(self)
      end

      def to_s
        name
      end
    end
  end
end
