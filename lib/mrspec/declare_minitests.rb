require 'minitest'
require 'mrspec/minitest_assertion_for_rspec'

require 'minitest/spec'

dsl = Minitest::Spec::DSL
it_location = dsl.instance_method(:it).source_location
dsl.instance_methods
   .map    { |name| [name, dsl.instance_method(name)] }
   .select { |name, method| method.source_location == it_location }
   .each   { |name, method|
     # Redefining Minitest::Spec#it, and aliases to record the block in the user's code,
     # this way the backtrace lines up with the logical definition site,
     # and we don't risk filtering the entire backtrace
     # which causes RSpec to abandon th filter, and the entire backtrace is quite distracting
     dsl.__send__ :define_method, name do |*args, &block|
       callsite = caller[0] || 'unknown-location:0:' # can't think of a case where this wouldn't be true, but just in case
       callsite =~ /^(.*?):(\d+):/
       caller_filename, caller_lineno = $1, $2.to_i
       block ||= eval 'proc { skip "(no tests defined)" }', binding, caller_filename, caller_lineno
       method.bind(self).call(*args, &block)
     end
   }


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
      example_group = rspec.describe group_name(klass), klass.class_metadata
      klass.runnable_methods.each do |method_name|
        wrap_test example_group, klass, method_name
      end
    end

    def wrap_test(example_group, klass, mname)
      metadata = klass.example_metadata[mname.intern]
      example  = example_group.example example_name(mname), metadata do
        instance = Minitest.run_one_method klass, mname
        next              if instance.passed?
        pending 'skipped' if instance.skipped?
        error = instance.failure.error
        raise error unless error.kind_of? Minitest::Assertion
        raise MinitestAssertionForRSpec.new error
      end
      fix_metadata example.metadata, klass.instance_method(mname)
    end

    def fix_metadata(metadata, method)
      file, line = method.source_location
      return unless file && line # not sure when this wouldn't be true, so no tests on it, but hypothetically it could happen
      metadata[:file_path]          = file
      metadata[:line_number]        = line
      metadata[:location]           = "#{file}:#{line}"
      metadata[:absolute_file_path] = File.expand_path(file)
    end
  end
end
