require 'minitest'
require 'mrspec/minitest_assertion_for_rspec'


module MRspec
  module DeclareMinitests
    extend self

    def self.call(rspec, minitest, klasses)
      init_minitest minitest
      wrap_classes rspec, klasses
    end

    def group_name(klass)
      if klass.name
        klass.name.to_s.sub(/^Test/, '').sub(/Test$/, '')
      else
        inspection = Kernel.instance_method(:inspect).bind(klass).call
        "Anonymous Minitest for class #{inspection}"
      end
    end

    def example_name(method_name)
      # remove test_, and turn underscores into spaces
      #   https://github.com/seattlerb/minitest/blob/f1081566ec6e9e391628bde3a26fb057ad2576a8/lib/minitest/test.rb#L62
      # remove test_0001_, where the number increments
      #   https://github.com/seattlerb/minitest/blob/f1081566ec6e9e391628bde3a26fb057ad2576a8/lib/minitest/spec.rb#L218-222
      method_name.to_s.sub(/^test_(?:\d{4}_)?/, '').tr('_', ' ')
    end

    def init_minitest(minitest)
      minitest.reporter = minitest::CompositeReporter.new # we're not using the reporter, but some plugins, (eg minitest/pride) expect it to be there
      minitest.load_plugins
      minitest.init_plugins minitest.process_args([])
    end

    def wrap_classes(rspec, klasses)
      klasses.each { |klass| wrap_class rspec, klass }
    end

    def wrap_class(rspec, klass)
      tests    = get_tests(klass)
      metadata = initial_metadata tests, klass.class_metadata, -1
      group    = rspec.describe group_name(klass), metadata
      tests.each { |mname, file, line| wrap_test group, klass, mname, file, line }
    end

    def wrap_test(example_group, klass, mname, file, line)
      metadata = initial_metadata [[mname, file, line]],
                                  klass.example_metadata[mname.intern],
                                  0

      example = example_group.example example_name(mname), metadata do
        instance = Minitest.run_one_method klass, mname
        next              if instance.passed?
        pending 'skipped' if instance.skipped?
        error = instance.failure.error
        raise error unless error.kind_of? Minitest::Assertion
        raise MinitestAssertionForRSpec.new error
      end
    end

    def get_tests(klass)
      klass.runnable_methods
           .map { |mname| [mname, *klass.instance_method(mname).source_location] }
           .sort_by { |name, file, line| line }
    end

    def initial_metadata(tests, existing_metadat, offset)
      # There is a disagreement here:
      # In RSpec, each describe block is its own example group, so the group will
      # all be defined in the same file. In Minitest, the example group is a class,
      # which can be reopened, thus the group can exist in multiple files.
      # I'm just going to ignore it for now, but prob the right thing to do is
      # to split the test methods into groups based on what file they are defined
      # in, and then what class they are defined in (currently, it is only what
      # class they are defined in)
      #
      # Leaving mrspec stuff in the backtrace, though, that way if we can't
      # successfully guess the caller, then it's more helpful as someone tries
      # to figure out wtf happened
      guessed_caller_entry = nil
      tests
        .select { |name, file, line| file && line }
        .take(1)
        .each { |_, file, line| guessed_caller_entry = "#{file}:#{line+offset}" }

      metadata = {}
      metadata[:caller] = [guessed_caller_entry, *caller] if guessed_caller_entry
      metadata.merge! existing_metadat

      metadata
    end
  end
end
