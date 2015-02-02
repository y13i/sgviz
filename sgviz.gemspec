# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sgviz/version'

Gem::Specification.new do |spec|
  spec.name          = "sgviz"
  spec.version       = Sgviz::VERSION
  spec.authors       = ["y13i"]
  spec.email         = ["email@y13i.com"]
  spec.summary       = %(Visualize VPC Security Groups.)
  spec.description   = %(A visualization tool for AWS VPC Security Groups.)
  spec.homepage      = "https://github.com/y13i/sgviz"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "gviz"
  spec.add_dependency "thor"
  spec.add_dependency "aws-sdk-resources"
  spec.add_dependency "aws-sdk-core"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "kumogata"
end
