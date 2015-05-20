# Gives access to configuration at the correct points in the lifecycle
module MRspec
  class Configuration < RSpec::Core::Configuration
    def initialize(*)
      super
      disable_monkey_patching!
      self.pattern = pattern.sub '_spec.rb', '_{spec,test}.rb' # look for files suffixed with both _spec and _test
      filter_gems_from_backtrace 'minitest'

      # Same as filter_gems_from_backtrace, except the version is not optional
      # This is necessary for local testing, where the test file would otherwise be filtered out b/c the project dir is mrspec,
      # which matches when the version is omitted
      backtrace_exclusion_patterns << /\/mrspec-[^\/]+\//

      # B/c the above requires the version, it won't filter out the lines from the lib,
      # so add a special case for that. Again, probably only necessary for testing within the gem
      backtrace_exclusion_patterns << /lib\/mrspec/
    end

    def load_spec_files(*)
      super                                         # will load the files
      MRspec::TransliterateMinitest.import_minitest # declare them to RSpec
    end
  end
end
