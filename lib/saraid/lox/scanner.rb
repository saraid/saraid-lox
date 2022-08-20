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
    end
  end
end
