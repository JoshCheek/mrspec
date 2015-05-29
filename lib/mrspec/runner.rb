require 'rspec/core/runner'

module MRspec
  class Runner < RSpec::Core::Runner
    def initialize(*)
      super
      # seems like there should be a better way, but I can't figure out what it is
      files_and_dirs = @options.options[:files_or_directories_to_run]
      return if files_and_dirs.any?
      files_and_dirs << 'spec' if File.directory? 'spec'
      files_and_dirs << 'test' if File.directory? 'test'
    end
  end
end
