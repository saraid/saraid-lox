require "saraid/lox/version"

require_relative 'lox/token_type'
require_relative 'lox/token'
require_relative 'lox/scanner'

module Saraid
  module Lox
    class Error < StandardError; end
    # Your code goes here...

    def self.main(args)
      if args.size > 1
        puts 'Usage: saraid-lox [script]'
        exit 64
      elsif args.size == 1
        run_file args.first
      else
        run_prompt
      end
    end

    def self.had_error?
      @had_error
    end

    def self.run_file(path)
      run File.read(path)
      exit 65 if had_error?
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

      puts tokens
    end

    def self.error(line, message)
      report line, '', message
    end

    def self.report(line, where, message)
      $stderr.puts "[line #{line}] Error#{where}: #{message}"
      @had_error = true
    end

    def self.generate_ast(superclass, definitions)
      superclass = const_set(superclass, Class.new)
      definitions.each do |subclass, parameters|
        const_set(subclass, Class.new(superclass) do
          define_method(:initialize) do |*arguments|
            parameters.each.with_index do |param, i|
              instance_variable_set(:"@#{param}", arguments[i])
            end
          end

          attr_reader *parameters
        end)
      end
    end
  end
end
require_relative 'lox/expr'
