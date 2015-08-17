require 'rspec/core'
require 'mrspec/declare_minitests'
require 'error_to_communicate/rspec_formatter'

module MRspec
  class Configuration < RSpec::Core::Configuration
    def initialize(*)
      super
      disable_monkey_patching!
      filter_gems_from_backtrace 'mrspec', 'minitest'
      self.pattern = pattern.sub '*_spec.rb', '{*_spec,*_test,test_*}.rb'
      self.default_formatter = WhatWeveGotHereIsAnErrorToCommunicate::RSpecFormatter
      Module.class_eval do
        def describe(*args, &block)
          Kernel.instance_method(:describe).bind(self).call(*args, &block)
        end
      end
    end

    def load_spec_files(*)
      super
      MRspec::DeclareMinitests.call(RSpec, Minitest, Minitest::Runnable.runnables)
    end

    def add_formatter(*args)
      if args.any? { |formatter| formatter == 'w' || formatter =~ /^what/ }
        super WhatWeveGotHereIsAnErrorToCommunicate::RSpecFormatter
      else
        super
      end
    end

  end
end
