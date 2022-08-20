module Saraid
  module Lox
    class Environment
      def initialize
        @values = {}
      end

      def define(name, value)
        @values[name] = value
      end

      def get(name)
        return @values[name.lexeme] if @values.key?(name.lexeme)
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end
    end
  end
end
