require 'rspec/core/runner'

module MRspec
  class Runner < RSpec::Core::Runner
    def initialize(*)
      super
      # seems like there should be a better way, but I can't figure out what it is
      files_and_dirs = @options.options[:files_or_directories_to_run]
      files_and_dirs << 'spec' << 'test' if files_and_dirs.empty?
    end
  end
end
