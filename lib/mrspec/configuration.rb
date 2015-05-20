# Gives access to configuration at the correct points in the lifecycle
module MRspec
  class Configuration < RSpec::Core::Configuration
    def initialize(*)
      super
      disable_monkey_patching!
      filter_gems_from_backtrace 'mrspec', 'minitest'
      self.pattern = pattern.sub '*_spec.rb', '{*_spec,*_test,test_*}.rb'
    end

    def load_spec_files(*)
      super                                         # will load the files
      MRspec::TransliterateMinitest.import_minitest # declare them to RSpec
    end
  end
end
