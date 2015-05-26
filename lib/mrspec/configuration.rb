require 'mrspec/declare_minitests'
require 'rspec/core'

module MRspec
  class Configuration < RSpec::Core::Configuration
    def initialize(*)
      super
      disable_monkey_patching!
      filter_gems_from_backtrace 'mrspec', 'minitest'
      self.pattern = pattern.sub '*_spec.rb', '{*_spec,*_test,test_*}.rb'
    end

    def load_spec_files(*)
      super
      MRspec::DeclareMinitests.call(RSpec, Minitest, Minitest::Runnable.runnables)
    end
  end
end
