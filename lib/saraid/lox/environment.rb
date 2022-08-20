module Saraid
  module Lox
    class Environment
      def initialize(enclosing = nil)
        @enclosing = enclosing
        @values = {}
      end

      def define(name, value)
        @values[name] = value
      end

      def get(name)
        return @values[name.lexeme] if @values.key?(name.lexeme)
        return @enclosing.get(name) if @enclosing
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end

      def assign(name, value)
        if @values.key?(name.lexeme)
          @values[name.lexeme] = value
          return
        end
        return @enclosing.assign(name, value) if @enclosing
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end
    end
  end
end
