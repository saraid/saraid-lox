require_relative './token'

module Saraid
  module Lox
    class Scanner
      KEYWORDS = [
        :and, :class, :else, :false, :fun, :for, :if, :nil, :or,
        :print, :return, :super, :this, :true, :var, :while,
      ].map(&:to_s)

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
        current >= source.size
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
        when '!' then add_token(match('=') ? :bang_equal : :bang)
        when '=' then add_token(match('=') ? :equal_equal : :equal)
        when '<' then add_token(match('=') ? :less_equal : :less)
        when '>' then add_token(match('=') ? :greater_equal : :greater)
        when '/'
          if match('/') then advance while peek != "\n" && !is_at_end?
          else add_token :slash
          end
        when ' ' then :ignore
        when "\r" then :ignore
        when "\t" then :ignore
        when "\n" then @line += 1
        when '"' then string
        else
          if is_digit?(c) then number
          elsif is_alpha?(c) then identifier
          else Lox.error line, "Unexpected character `#{c}`"
          end
        end
      end

      private def advance
        source[current].tap { @current += 1 }
      end

      private def add_token(type, literal = nil)
        text = source[start...current]
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

      private def string
        while peek != '"' && !is_at_end?
          @line += 1 if peek == "\n"
          advance
        end

        if is_at_end?
          Lox.error(line, "Unterminated string.")
          return
        end

        # The closing ".
        advance

        # Trim the surrounding quotes.
        value = source[(start + 1)...(current - 1)]
        add_token(:string, value);
      end

      private def is_digit?(c)
        c.match?(/\d/)
      end

      private def number
        advance while is_digit?(peek)
        fractional = false

        # Look for a fractional part.
        if peek == '.' && is_digit?(peek_next)
          # Consume the "."
          advance

          advance while is_digit?(peek)
          fractional = true
        end

        add_token(:number, source[start...current].to_f)
      end

      private def peek_next
        return "\0" if current + 1 >= source.size
        source[current + 1]
      end

      private def identifier
        advance while is_alphanumeric?(peek)

        text = source[start...current]
        type = KEYWORDS.find { text == _1 }&.to_sym || :identifier

        add_token type
      end

      private def is_alpha?(c)
        c.match?(/[A-Za-z_]/)
      end

      private def is_alphanumeric?(c)
        is_alpha?(c) || is_digit?(c)
      end
    end
  end
end
