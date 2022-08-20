module Saraid
  module Lox
    class Token
      def initialize(type, lexeme, literal, line)
        @type, @lexeme, @literal, @line = type, lexeme, literal, line
        raise TypeError unless TokenType.registered?(@type)
      end
      attr_reader :type, :lexeme, :literal, :line

      def to_s
        [type, lexeme, literal].join(' ')
      end
    end
  end
end
