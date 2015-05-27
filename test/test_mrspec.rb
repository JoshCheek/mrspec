require 'minitest/spec'
require 'support/helper'
require 'support/mock'


# Just wrote down the behaviour,
# but as of right now, it's not worth the effort of writing all of them,
# the cukes test all this behaviour, already

class TestMRspec < Minitest::Spec
  include ::Mock

  describe 'default files and patterns' do
    it 'looks in the test and spec directories'
    it 'finds files that end in _spec.rb, recursively'
    it 'finds files that end in _test.rb, recursively'
    it 'finds files that begin with test_ and end with .rb, recursively'
  end

  describe 'registering tests' do
    it 'registers Minitest::Test tests with RSpec, using the class name' do
      test1 = a_test_named 'First'
      test2 = a_test_named 'Second'
      MRspec::DeclareMinitests.wrap_classes mock_rspec, [test1, test2]
      assert_equal ['First', 'Second'], mock_rspec.group_names
    end

    it 'registers Minitest::Spec tests with RSpec, using the spec description' do
      spec1 = a_spec_named 'spec 1'
      spec2 = a_spec_named 'spec 2'
      MRspec::DeclareMinitests.wrap_classes mock_rspec, [test1, test2]
      assert_equal ['spec 1', 'spec 2'], mock_rspec.group_names
    end

    describe 'descriptions' do
      def description_for(class_name)
        MRspec::DeclareMinitests.group_name a_test_named(class_name)
      end

      it 'removes leading `Test` in the class name, from the description' do
        assert_equal 'ClassName', description_for('ClassName')
        assert_equal 'ClassName', description_for('TestClassName')
      end

      it 'removes trailing `Test` in the class name, from the description' do
        assert_equal 'ClassName', description_for('ClassName')
        assert_equal 'ClassName', description_for('ClassNameTest')
      end

      it 'can deals with anonymous classes (nil class name) by using their to_s' do
        klass1       = a_test_named nil
        description1 = MRspec::DeclareMinitests.group_name klass1

        klass2       = a_test_named nil
        description2 = MRspec::DeclareMinitests.group_name klass2

        assert_match /^Anonymous Minitest for class #<Class:0x/, description1

        # Just double checking it's bypassing this code that makes them all have the same name:
        # https://github.com/seattlerb/minitest/blob/f1081566ec6e9e391628bde3a26fb057ad2576a8/lib/minitest/assertions.rb#L118
        refute_equal description1, description2
      end

      it 'can deal with symol or string names' do
        assert_equal 'ClassName', description_for('ClassName')
        assert_equal 'ClassName', description_for(:ClassName)
      end
    end

    describe 'example names' do
      def example_name_for(method_name)
        MRspec::DeclareMinitests.example_name method_name
      end

      it 'removes leading `test_` in the method name, from the test name' do
        assert_equal 'methodname', example_name_for('methodname')
        assert_equal 'methodname', example_name_for('test_methodname')
      end

      it 'removes leading `test_nnnn_` in the method name, from the test name' do
        assert_equal 'methodname', example_name_for('methodname')
        assert_equal 'methodname', example_name_for('test_0000_methodname')
        assert_equal '000 methodname', example_name_for('test_000_methodname')
      end

      it 'translates underscores to spaces' do
        assert_equal 'a method name', example_name_for('a_method_name')
      end

      it 'can deal with string or symbol names' do
        assert_equal 'methodname', example_name_for('methodname')
        assert_equal 'methodname', example_name_for(:methodname)
      end
    end

    describe 'metadata' do
      it 'aggregates metadata on the class with classmeta' do
        klass = a_test_named('a') { classmeta a: true }
        assert_equal({a: true}, klass.class_metadata)
      end

      it 'allows for multiple metadata keys to be provided in one classmeta call' do
        klass = a_test_named('a') { classmeta a: true, b: true }
        assert_equal({a: true, b: true}, klass.class_metadata)
      end

      it 'aggregates multiple calls to classmeta' do
        klass = a_test_named 'a' do
          classmeta a: true
          classmeta b: true
        end
        assert_equal({a: true, b: true}, klass.class_metadata)
      end

      it 'aggregates metadata on the next test to be defined, with meta' do
        klass = a_test_named 'a' do
          meta a: true
          def test_a; end

          def test_b; end

          meta c: true
          def test_c; end
        end

        assert_equal({a: true}, klass.example_metadata[:test_a])
        assert_equal({},        klass.example_metadata[:test_b])
        assert_equal({c: true}, klass.example_metadata[:test_c])
      end

      it 'allows for multiple metadata keys to be provided in one meta call' do
        klass = a_test_named 'a' do
          meta a: true, b: true
          def test_a; end
        end
        assert_equal({a: true, b: true}, klass.example_metadata[:test_a])
      end

      it 'aggregates multiple calls to meta' do
        klass = a_test_named 'a' do
          meta a: true
          meta b: true
          def test_a; end
        end
        assert_equal({a: true, b: true}, klass.example_metadata[:test_a])
      end
    end
  end

  describe 'recording tests' do
    it 'records minitest errors as failures, and displays the message and the class'
    it 'records minitest failed assertions as failures, and displays the message, but not the class'
    it 'records rspec errors as failures, and displays the message, and the class'
    it 'records rspec failed assertions as failures, and displays the message and the class'
    it 'omits minitest code from the backtrace'
    it 'omits rspec code from the backtrace'
    it 'omits mrspec code from the backtrace'
    it 'allows Minitest::Spec to be declared without bodies, and backtrace shows the call to the it block'
  end

  describe 'identifying which test to run' do
    it 'matches the -e flag against Minitest tests'
    it 'overrides the default filenames, when one is provided'
  end

  describe 'toplevel `describe`' do
    it 'comes from Minitest::Spec' do
      filename, _linenum = TOPLEVEL_BINDING.method(:describe).source_location
      assert_match /minitest/, filename
      refute_match /rspec/,    filename
    end
  end
end
