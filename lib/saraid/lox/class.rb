module Saraid
  module Lox
    class LoxInstance
      def initialize(klass)
        @klass = klass
      end
      attr_reader :klass

      def to_s
        "#{klass.name} instance"
      end
    end
  end
end
