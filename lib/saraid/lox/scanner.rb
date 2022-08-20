require_relative './token'

module Saraid
  module Lox
    class Scanner
      def initialize(source)
        @source = source
        @tokens = []
        @start, @current, @line = 0, 0, 1
      end
      attr_reader :source, :tokens
      attr_reader :start, :current, :line

      def scan_tokens
        until is_at_end? do
          # We are at the beginning of the next lexeme.
          start = current
          scan_token
        end

        tokens << Token.new(:eof, '', nil, line)
      end

      def is_at_end?
        current >= source.size
      end

      def scan_token
        c = advance
        case c
        when '(' then add_token :left_paren
        when ')' then add_token :right_paren
        when '{' then add_token :left_brace
        when '}' then add_token :right_brace
        when ',' then add_token :comma
        when '.' then add_token :dot
        when '-' then add_token :minus
        when '+' then add_token :plus
        when ';' then add_token :semicolon
        when '*' then add_token :star
        end
      end

      def advance
        source[current+=1]
      end

      def add_token(type, literal = nil)
        text = source[start, current]
        tokens << Token.new(type, text, literal, line)
      end
    end
  end
end
