module Saraid
  module Lox
    class Environment
      def initialize(enclosing = nil)
        @enclosing = enclosing
        @values = {}
      end
      attr_reader :values, :enclosing

      def define(name, value)
        @values[name] = value
      end

      def get(name)
        return @values[name.lexeme] if @values.key?(name.lexeme)
        return @enclosing.get(name) if @enclosing
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end

      def getAt(distance, name)
        ancestor(distance).values[name]
      end

      def ancestor(distance)
        distance.times.reduce(self) { _1.enclosing }
      end

      def assign(name, value)
        if @values.key?(name.lexeme)
          @values[name.lexeme] = value
          return
        end
        return @enclosing.assign(name, value) if @enclosing
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end

      def assignAt(distance, name, value)
        ancestor(distance).values[name.lexeme] = value
      end
    end
  end
end
