# presumably this is loose enough to not whine all the time, but tight enough to not break
require 'rspec/core'
require 'minitest'

# Allow Minitest to support RSpec's metadata (eg tagging)
# Thus you can tag a test or a class, and then pass `-t mytag` to mrspec,
# and it will only run the tagged code.
class << Minitest::Runnable
  # Add metadata to the current class
  def classmeta(metadata)
    class_metadata.merge! metadata
  end

  # Add metadata to the next defined test
  def meta(metadata)
    pending_metadata.merge! metadata
  end

  def class_metadata
    @selfmetadata ||= {}
  end

  def example_metadata
    @metadata ||= Hash.new { |metadata, mname| metadata[mname] = {} }
  end

  private

  def method_added(manme)
    example_metadata[manme.intern].merge! pending_metadata
    pending_metadata.clear
  end

  def pending_metadata
    @pending_metadata ||= {}
  end
end


# The code that imports Minitest into RSpec
module MRspec
  VERSION = '1.0.0'

  def self.group_name(klass)
    klass.inspect.sub /Test$/, ''
  end

  def self.example_name(method_name)
    method_name.to_s.sub(/^test_/, '').tr('_', ' ')
  end

  def self.import_minitest
    Minitest.reporter = Minitest::CompositeReporter.new # we're not using the reporter, but some plugins, (eg minitest/pride) expect it to be there
    Minitest.load_plugins
    Minitest.init_plugins Minitest.process_args([])

    Minitest::Runnable.runnables.each { |klass| wrap_class klass }
  end

  def self.wrap_class(klass)
    example_group = RSpec.describe group_name(klass), klass.class_metadata
    klass.runnable_methods.each do |method_name|
      wrap_test example_group, klass, method_name
    end
  end

  def self.wrap_test(example_group, klass, mname)
    metadata = klass.example_metadata[mname.intern]
    example = example_group.example example_name(mname), metadata do
      instance = Minitest.run_one_method klass, mname
      instance.passed?  and next
      instance.skipped? and pending 'skipped'
      raise instance.failure
    end

    fix_metadata example.metadata, klass.instance_method(mname)
  end

  def self.fix_metadata(metadata, method)
    file, line = method.source_location
    return unless file && line # not sure when this wouldn't be true, so no tests on it, but hypothetically it could happen
    metadata[:file_path]          = file
    metadata[:line_number]        = line
    metadata[:location]           = "#{file}:#{line}"
    metadata[:absolute_file_path] = File.expand_path(file)
  end
end


# Custom runner to gain access to configuration at the correct point in the lifecycle
class MRspec::Runner < RSpec::Core::Runner
  def initialize(*)
    super
    # seems like there should be a better way, but I can't figure out what it is
    files_and_dirs = @options.options[:files_or_directories_to_run]
    files_and_dirs << 'spec' << 'test' if files_and_dirs.empty?
  end
end


# Custom configuration to gain access to configuration at the correct point in the lifecycle
class MRspec::Configuration < RSpec::Core::Configuration
  def initialize(*)
    super
    disable_monkey_patching!
    filter_gems_from_backtrace 'minitest'
    backtrace_exclusion_patterns << /mrspec\.rb:/
    self.pattern = pattern.sub '_spec.rb', '_{spec,test}.rb' # look for files suffixed with both _spec and _test
  end

  def load_spec_files(*)
    super                  # will load the files
    MRspec.import_minitest # declare them to RSpec
  end
end

RSpec.configuration = MRspec::Configuration.new
