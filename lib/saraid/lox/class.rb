module Saraid
  module Lox
    class LoxInstance
      def initialize(klass)
        @klass = klass
        @fields = {}
      end
      attr_reader :klass, :fields

      def get(name)
        return fields[name.lexeme] if fields.key?(name.lexeme)

        klass_method = klass.findMethod(name.lexeme)
        return klass_method.bind(self) if klass_method

        raise RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
      end

      def set(name, value)
        fields[name.lexeme] = value
      end

      def to_s
        "#{klass.name} instance"
      end
    end
  end
end
