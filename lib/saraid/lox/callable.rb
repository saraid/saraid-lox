module Saraid
  module Lox
    class LoxCallable
    end

    class LoxFunction < LoxCallable
      def initialize(declaration, closure, is_initializer)
        @declaration = declaration
        @closure = closure
        @is_initializer = is_initializer
      end
      attr_reader :declaration, :closure

      def is_initializer?
        @is_initializer
      end

      def arity
        declaration.params.size
      end

      def bind(instance)
        environment = Environment.new(closure)
        environment.define('this', instance)
        LoxFunction.new(declaration, environment, @is_initializer)
      end

      def call(interpreter, arguments)
        environment = Environment.new(closure)
        declaration.params.each.with_index do |param, i|
          environment.define(param.lexeme, arguments[i])
        end

        begin
          interpreter.executeBlock(declaration.body, environment)
        rescue Interpreter::Return => returnStmt
          return closure.get(0, 'this') if is_initializer?
          return returnStmt.value
        end

        return closure.get(0, 'this') if is_initializer?

        nil
      end

      def to_s
        "<fn #{declaration.name.lexeme}>"
      end
    end

    class LoxClass < LoxCallable
      def initialize(name, superclass, methods)
        @name = name
        @superclass = superclass
        @methods = methods
      end
      attr_reader :name, :superclass, :methods

      def arity
        findMethod('init')&.arity || 0
      end

      def call(interpreter, arguments)
        instance = LoxInstance.new(self)
        findMethod('init')&.bind(instance).call(interpreter, arguments)
        instance
      end

      def findMethod(name)
        return @methods[name] if @methods.key?(name)
        nil
      end

      def to_s
        name
      end
    end
  end
end
