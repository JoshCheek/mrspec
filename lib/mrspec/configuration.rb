# Gives access to configuration at the correct points in the lifecycle
module MRspec
  class Configuration < RSpec::Core::Configuration
    def initialize(*)
      super
      disable_monkey_patching!
      filter_gems_from_backtrace 'mrspec', 'minitest'
      self.pattern = pattern.sub '_spec.rb', '_{spec,test}.rb' # look for files suffixed with both _spec and _test
    end

    def load_spec_files(*)
      super                                         # will load the files
      MRspec::TransliterateMinitest.import_minitest # declare them to RSpec
    end
  end
end
