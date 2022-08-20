module Saraid
  module Lox
    module TokenType

      def self.register(*token_types)
        @registry ||= []
        token_types.each { @registry << _1 }
      end

      register(
        # Single-character tokens.
        :left_paren, :right_paren, :left_brace, :right_brace,
        :comma, :dot, :minus, :plus, :semicolon, :slash, :star,

        # One or two character tokens.
        :bang, :bang_equal,
        :equal, :equal_equal,
        :greater, :greater_equal,
        :less, :less_equal,

        # Literals.
        :identifier, :string, :number,

        # Keywords.
        :and, :class, :else, :false, :fun, :for, :if, :nil, :or,
        :print, :return, :super, :this, :true, :var, :while,

        :eof
      )
    end
  end
end
