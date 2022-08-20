module Saraid
  module Lox
    class Error < StandardError; end
    class RuntimeError < Lox::Error
      def initialize(token, message)
        super(message)
        @token = token
      end
      attr_reader :token
    end
  end
end
