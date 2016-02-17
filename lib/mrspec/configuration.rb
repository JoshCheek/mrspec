require 'rspec/core'
require 'mrspec/declare_minitests'
require 'error_to_communicate/rspec_formatter'

module MRspec
  class Configuration < RSpec::Core::Configuration
    def initialize(*)
      super
      # Turn color on by default, b/c everyone I know that uses it uses colour, so make it opt-out rather than opt-in
      # https://github.com/JoshCheek/mrspec/issues/12
      # Defaulted here: https://github.com/rspec/rspec-core/blob/44afa9bd83e655b4d1fa60c0d73373a754aa479b/lib/rspec/core/configuration.rb#L367
      # Exposed here:   https://github.com/rspec/rspec-core/blob/44afa9bd83e655b4d1fa60c0d73373a754aa479b/lib/rspec/core/configuration.rb#L715-L722
      @color = true

      disable_monkey_patching!
      filter_gems_from_backtrace 'mrspec', 'minitest', 'interception', 'what_weve_got_here_is_an_error_to_communicate'
      self.pattern = pattern.sub '*_spec.rb', '{*_spec,*_test,test_*}.rb'
      self.default_formatter = WhatWeveGotHereIsAnErrorToCommunicate::RSpecFormatter
      WhatWeveGotHereIsAnErrorToCommunicate::ExceptionRecorder.record_exception_bindings(self)

      [Module, TOPLEVEL_BINDING.eval('self').singleton_class].each do |klass|
        klass.class_eval do
          def describe(*args, &block)
            Kernel.instance_method(:describe).bind(self).call(*args, &block)
          end
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
