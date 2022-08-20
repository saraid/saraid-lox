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
          @start = current
          scan_token
        end

        tokens << Token.new(:eof, '', nil, line)
      end

      private def is_at_end?
        current >= source.size - 1 # TODO: Why did I have to subtract 1?
      end

      private def scan_token
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
        when '!' then add_token(match('=') ? BANG_EQUAL : BANG)
        when '=' then add_token(match('=') ? EQUAL_EQUAL : EQUAL)
        when '<' then add_token(match('=') ? LESS_EQUAL : LESS)
        when '>' then add_token(match('=') ? GREATER_EQUAL : GREATER)
        when '/'
          if match('/') then advance while peek != "\n" && !is_at_end?
          else add_token :slash
          end
        when ' ' then :ignore
        when "\r" then :ignore
        when "\t" then :ignore
        when "\n" then @line += 1
        else Lox.error line, 'Unexpected character'
        end
      end

      private def advance
        source[@current += 1]
      end

      private def add_token(type, literal = nil)
        text = source[start, current]
        tokens << Token.new(type, text, literal, line)
      end

      private def match(expected)
        return false if is_at_end?
        return false if source[current] != expected

        @current += 1
        true
      end

      private def peek
        return "\0" if is_at_end?
        source[current]
      end
    end
  end
end
