require 'mrspec/transcribe_minitest'
require 'rspec/core' # apparenlty you can't require just configuration alone

module MRspec
  class Configuration < RSpec::Core::Configuration
    def initialize(*)
      super
      disable_monkey_patching!
      filter_gems_from_backtrace 'mrspec', 'minitest'
      self.pattern = pattern.sub '*_spec.rb', '{*_spec,*_test,test_*}.rb'
    end

    def load_spec_files(*)
      super                           # will load the files
      MRspec::TranscribeMinitest.call # declare them to RSpec
    end
  end
end
