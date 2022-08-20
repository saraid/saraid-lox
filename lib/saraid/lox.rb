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
        break if line.nil?

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
  end
end
