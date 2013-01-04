# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uci/version'

Gem::Specification.new do |gem|
  gem.name          = "uci"
  gem.version       = Uci::VERSION
  gem.authors       = ["Matthew Nielsen"]
  gem.email         = ["xunker@pyxidis.org"]
  gem.description   = %q{Ruby library for the Universal Chess Interface (UCI)}
  gem.summary       = %q{Ruby library for the Universal Chess Interface (UCI)}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.has_rdoc = false
  # gem.add_dependency('faraday', '0.8.4')
  gem.add_development_dependency('simplecov', '0.7.1')
  gem.add_development_dependency('rspec', '2.12.0')
end
