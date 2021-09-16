# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'offline_sort/version'

Gem::Specification.new do |spec|
  spec.name          = "offline-sort"
  spec.version       = OfflineSort::VERSION
  spec.authors       = ["Matthew Cross"]
  spec.email         = ["mcross@salsify.com"]
  spec.description   = %q{Offline sort for any enumerable with pluggable serialization strategies}
  spec.summary       = %q{Offline sort for any enumerable with pluggable serialization strategies}
  spec.homepage      = "https://github.com/salsify/offline-sort"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "msgpack"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'salsify_rubocop', '~> 1.0.1'
end
