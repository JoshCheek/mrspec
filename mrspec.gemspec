$:.push File.expand_path("../lib", __FILE__)
require "mrspec/version"

Gem::Specification.new do |s|
  s.name        = "mrspec"
  s.version     = MRspec::VERSION
  s.authors     = ["Josh Cheek"]
  s.email       = ["josh.cheek@gmail.com"]
  s.homepage    = "https://github.com/JoshCheek/mrspec"
  s.summary     = %q{Minitest and RSpec, sitting in a tree, T. E. S. T. I. N. G!}
  s.description = %q{Allows you to run Minitest tests and specs with RSpec's runner, thus you can write both Minitest and RSpec, side-by-side, and take advantage of the many incredibly helpful features it supports (primarily: better formatters, --colour, --fail-fast, and tagging).}
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n") - Dir['mascots/*']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = ['mrspec']
  s.require_paths = ['lib']

  # b/c we go into the guts of RSpec, we're sensitive to private API changes,
  # in this case, we need https://github.com/rspec/rspec-core/commit/d52c969
  # which was released as part of v3.5.0
  s.add_dependency "rspec-core", "~> 3.5.0"

  s.add_dependency "minitest",   "~> 5.0"
  s.add_dependency "what_weve_got_here_is_an_error_to_communicate", "~> 0.0.8"

  s.add_development_dependency "haiti",    ">= 0.2.2", "< 0.3"
  s.add_development_dependency "cucumber", "~> 2.0"
end
