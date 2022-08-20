require_relative 'lib/saraid/lox/version'

Gem::Specification.new do |spec|
  spec.name          = "saraid-lox"
  spec.version       = Saraid::Lox::VERSION
  spec.authors       = ["Michael Chui"]
  spec.email         = ["saraid216@gmail.com"]

  spec.summary       = %q{Implementing the Lox language from Crafting Interpreters.}
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'byebug'
end
