module Saraid
  module Lox
    class Token
      def initialize(type, lexeme, literal, line)
        @type, @lexeme, @literal, @line = type, lexeme, literal, line
      end
      attr_reader :type, :lexeme, :literal, :line

      def to_s
        [type, lexeme, literal].join(' ')
      end
    end
  end
end
