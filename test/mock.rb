module Mock
  def mock_rspec
    @mock_rspec ||= Mock::RSpec.new
  end

  def mock_minitest
    @mock_minitest ||= Mock::Minitest.new
  end

  # This name can't match /^test_/, or https://github.com/seattlerb/minitest/blob/f1081566ec6e9e391628bde3a26fb057ad2576a8/lib/minitest/spec.rb#L167-171
  # ...legit thought I'd forgotten the object model for a moment there O.o
  def a_test_named(name)
    Class.new Mock::MinitestTest do
      define_singleton_method(:name) { name }
    end
  end
end

class Mock::MinitestTest < ::Minitest::Test
  # noop, just preventing our testing from globally registering tests
  def self.inherited(*)
  end

  # And unregister this mock class
  Minitest::Runnable.runnables.delete self
end

class Mock::RSpec
  def groups
    @groups ||= []
  end

  def group_names
    groups.map &:name
  end

  def examples
    groups.flat_map &:examples
  end

  def describe(name, metadata, &block)
    group = ExampleGroup.new name, metadata
    groups << group
    group.module_exec(&block) if block # https://github.com/rspec/rspec-core/blob/c7c1154934c42b5f6905bb7bd22025fe6c8a816c/lib/rspec/core/example_group.rb#L363
    group
  end
end

Mock::RSpec::Example = Struct.new :name, :metadata, :block

Mock::RSpec::ExampleGroup = Struct.new :name, :metadata do
  def examples
    @examples ||= []
  end

  def example(name, metadata, &block)
    Example.new name, metadata, block
  end
end
