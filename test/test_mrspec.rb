require 'minitest/spec'

# Just wrote down the behaviour,
# but as of right now, it's not worth the effort of writing these as unit tests'

class TestMRspec < Minitest::Spec
  describe 'default files and patterns' do
    it 'looks in the test and spec directories'
    it 'finds files that end in _spec.rb, recursively'
    it 'finds files that end in _test.rb, recursively'
    it 'finds files that begin with test_ and end with .rb, recursively'
  end

  describe 'registering tests' do
    it 'registers Minitest::Test tests with RSpec'
    it 'registers Minitest::Spec tests with RSpec'
    it 'registers RSpec::Core::ExampleGroup tests with RSpec'

    describe 'descriptions' do
      it 'registers the class name as the description'
      it 'removes leading `Test` in the class name, from the description'
      it 'removes trailing `Test` in the class name, from the description'
    end

    describe 'test names' do
      it 'removes leading `test_` in the method name, from the test name'
      it 'removes leading `test_nnnn_` in the method name, from the test name'
      it 'translates underscores to spaces'
    end

    describe 'metadata' do
      it 'aggregates metadata on the class with classmeta'
      it 'allows for multiple metadata keys to be provided in one classmeta call'
      it 'aggregates multiple calls to classmeta'
      it 'aggregates metadata on the next test to be defined, with meta'
      it 'allows for multiple metadata keys to be provided in one meta call'
      it 'aggregates multiple calls to meta'
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
