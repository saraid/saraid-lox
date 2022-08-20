require "saraid/lox/version"

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

    def self.main(args)
      if args.size > 1
        puts 'Usage: saraid-lox [script]'
        exit 64
      elsif args.size == 1
        run_file args.first
      elsif $stdin.stat.pipe?
        run $stdin.read
      else
        run_prompt
      end
    end

    def self.had_error?
      @had_error
    end

    def self.had_runtime_error?
      @had_runtime_error
    end

    def self.run_file(path)
      run File.read(path)
      exit 65 if had_error?
      exit 70 if had_runtime_error?
    end

    def self.run_prompt
      loop do
        line = $stdin.gets
        puts line.inspect
        break if line == "\n"

        run line
        @had_error = false
      end
    end

    def self.run(source)
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens
      parser = Parser.new(tokens)
      stmts = parser.parse

      return if had_error?

      @interpreter ||= Interpreter.new
      @interpreter.interpret(stmts)
    end

    def self.error(token_or_line, message)
      case token_or_line
      when Token
        token = token_or_line
        if token.type == :eof then report(token.line, ' at end', message)
        else report(token.line, "at '#{token.lexeme}'", message)
        end
      else
        line = token_or_line
        report line, '', message
      end
    end

    def self.report(line, where, message)
      $stderr.puts "[line #{line}] Error#{where}: #{message}"
      @had_error = true
    end

    def self.runtime_error(error)
      $stderr.puts "#{error.message}\n[line #{error.token.line}]"
      @had_runtime_error = true
    end

    def self.generate_ast(superclass_name, definitions)
      superclass = const_set(superclass_name, Class.new)
      definitions.each do |subclass, parameters|
        superclass.const_set(subclass, Class.new(superclass) do
          define_method(:initialize) do |*arguments|
            parameters.each.with_index do |param, i|
              instance_variable_set(:"@#{param}", arguments[i])
            end
          end
          attr_reader *parameters

          define_method(:accept) do |visitor|
            visitor.send(:"visit#{subclass}#{superclass_name}", self)
          end
        end)
      end
    end
  end
end
require_relative 'lox/ast'

require_relative 'lox/token_type'
require_relative 'lox/token'
require_relative 'lox/scanner'
require_relative 'lox/ast_printer'
require_relative 'lox/parser'
require_relative 'lox/interpreter'
require_relative 'lox/environment'
require_relative 'lox/callable'
