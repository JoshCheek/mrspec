Feature: mrspec
  Minitest doesn't have a runner, but a runner would be really nice.
  RSpec has a nice runner... so lets join them together!

  Scenario: Finds spec/**/*_spec.rb and test/**/*_test.rb and test/**/test_*.rb
    Given the file "spec/a_spec.rb":
    """
    RSpec.describe 'a' do
      it('passes') { }
    end
    """
    And the file "spec/dir/b_spec.rb":
    """
    RSpec.describe 'b' do
      it('passes') { }
    end
    """
    And the file "test/c_test.rb":
    """
    class CTest < Minitest::Test
      def test_passes
      end
    end
    """
    And the file "test/dir/d_test.rb":
    """
    class DTest < Minitest::Test
      def test_passes
      end
    end
    """
    And the file "test/dir/test_e.rb":
    """
    class ETest < Minitest::Test
      def test_passes
      end
    end
    """
    And the file "test/a_test_file.rb":
    """
    raise "I should not be loaded!"
    """
    And the file "spec/a_spec_file.rb":
    """
    raise "I should not be loaded!"
    """
    When I run 'mrspec -f json'
    Then the program ran successfully
    And stdout includes "5 examples"
    And stdout includes "0 failures"


  Scenario: It works when there is only a spec dir
    Given the file "spec/something_spec.rb":
    """
    RSpec.describe 'a' do
      it('b') { }
    end
    """
    When I run "mrspec"
    Then the program ran successfully


  Scenario: It works when there is only a test dir
    Given the file "test/something_spec.rb":
    """
    class A < Minitest::Test
      def test_b
      end
    end
    """
    When I run "mrspec"
    Then the program ran successfully


  Scenario: Registers minitest tests as RSpec tests, recording skips, passes, errors, failures
    Given the file "some_test.rb":
    """
    class LotaStuffsTest < Minitest::Test
      def test_passes
      end

      def test_fails
        assert_equal 1, 2
      end

      def test_errors
        raise 'omg'
      end

      def test_skips
        skip
      end
    end
    """
    When I run "mrspec some_test.rb --no-color --format progress"

    # counts correctly
    Then stdout includes "4 examples"
    And stdout includes "2 failures"
    And stdout includes "1 pending"
    And stdout does not include "No examples found"

    # displays the failed assertion, not an error
    And stdout includes "Expected: 1"
    And stdout includes "Actual: 2"

    # displays the test's code, not the integration code
    And stdout includes "raise 'omg'"
    And stdout includes "assert_equal 1, 2"
    And stdout does not include "Minitest.run_one_method"


  Scenario: Minitest::Spec definitions without bodies show line of the declaration in the backtrace, and not the full backtrace
    Given the file "skip_spec.rb":
    """
    require 'minitest/spec'
    describe 'a' do
      it 'has no body'
      it('calls skip') { skip }
    end

    class A < Minitest::Spec
      it 'has no body'
      it('calls skip') { skip }
    end

    class Wat < Minitest::Test
      extend Minitest::Spec::DSL
      register_spec_type /^lol/, self
    end
    describe 'lol' do
      it 'has no body'
      it('calls skip') { skip }
    end
    """
    When I run "mrspec skip_spec.rb"
    Then stdout includes "skip_spec.rb:3"
    Then stdout includes "skip_spec.rb:4"
    Then stdout includes "skip_spec.rb:8"
    Then stdout includes "skip_spec.rb:9"
    Then stdout includes "skip_spec.rb:17"
    Then stdout includes "skip_spec.rb:18"
    And stdout does not include "/mrspec/"


  Scenario: Works with Minitest::Test, choosing intelligent names
    Given the file "some_test.rb":
    """
    class MyClass1Test < Minitest::Test
      def test_it_does_stuff
      end
    end

    class TestMyClass2 < Minitest::Test
      def test_it_does_stuff
      end
    end
    """
    When I run "mrspec some_test.rb -f json"
    Then the program ran successfully
    And stdout includes '"full_description":"MyClass1 it does stuff"'
    And stdout includes '"full_description":"MyClass2 it does stuff"'


  Scenario: Works with Minitest::Spec, choosing intelligent names
    Given the file "some_spec.rb":
    """
    require 'minitest/spec'
    describe 'the description' do
      it 'the example' do
        assert true
        if kind_of? Minitest::Spec
          puts "I am defined by Minitest::Spec"
        end
      end
    end
    """
    When I run "mrspec some_spec.rb -f json"
    Then stdout includes "1 example"
    And stdout includes "0 failures"
    And stdout includes "I am defined by Minitest::Spec"
    And stdout includes '"description":"the example"'
    And stdout includes '"full_description":"the description the example"'


  Scenario: Filters the runner, minitest code, interception, and what-we-ve-got-here-is-an-error-to-communicate out of the backtrace
    Given the file "some_test.rb":
    """
    class LotaStuffsTest < Minitest::Test
      def test_errors
        raise "zomg"
      end
    end
    """
    When I run "mrspec some_test.rb"
    Then stdout does not include "minitest"
    And stdout does not include "mrspec.rb"
    And stdout does not include "bin/mrspec"
    And stdout does not include "interception"
    And stdout does not include "what_weve_got_here_is_an_error_to_communicate"


  Scenario: --fail-fast flag
    Given the file "fails_fast_test.rb":
    """
    class TwoFailures < Minitest::Test
      i_suck_and_my_tests_are_order_dependent!
      def test_1
        raise
      end
      def test_2
        raise
      end
    end
    """
    When I run 'mrspec fails_fast_test.rb --fail-fast'
    Then stdout includes "1 example"


  Scenario: -e flag
    Given the file "spec/first_spec.rb":
    """
    RSpec.describe 'a' do
      example('b') { }
    end
    """
    Given the file "test/first_test.rb":
    """
    class FirstTest < Minitest::Test
      def test_1
      end
    end
    """
    And the file "test/second_test.rb":
    """
    class SecondTest < Minitest::Test
      def test_2
      end
    end
    """
    When I run 'mrspec -e Second'
    Then stdout includes "1 example"
    And stdout does not include "2 examples"


  Scenario: Passing a filename overrides the default pattern
    Given the file "spec/first_spec.rb":
    """
    RSpec.describe 'first spec' do
      example('rspec 1') { }
    end
    """
    Given the file "test/first_test.rb":
    """
    class FirstTest < Minitest::Test
      def test_minitest_1
      end
    end
    """
    And the file "test/second_test.rb":
    """
    class SecondTest < Minitest::Test
      def test_minitest_2
      end
    end
    """
    When I run 'mrspec -f d test/second_test.rb'
    Then stdout includes "1 example"
    And  stdout includes "minitest 2"
    And  stdout does not include "rspec 1"
    And  stdout does not include "minitest 1"


  Scenario: Can add metadata to examples, ie run only tagged tests
    Given the file "test/tag_test.rb":
    """
    class TagTest < Minitest::Test
      meta first: true
      def test_1
        puts "ran test 1"
      end

      # multiple tags in meta, and aggregated across metas
      meta second: true, second2: true
      meta second3: true
      def test_2
        puts "ran test 2"
      end

      def test_3
        puts "ran test 3"
      end
    end
    """

    # only test_1 is tagged w/ first
    When I run 'mrspec test/tag_test.rb -t first'
    Then the program ran successfully
    Then stdout includes "1 example"
    And stdout includes "ran test 1"
    And stdout does not include "ran test 2"
    And stdout does not include "ran test 3"

    # test_2 is tagged w/ second, and second2 (multiple tags in 1 meta)
    When I run 'mrspec test/tag_test.rb -t second'
    Then stdout includes "1 example"
    And stdout includes "ran test 2"
    And stdout does not include "ran test 1"
    And stdout does not include "ran test 3"

    When I run 'mrspec test/tag_test.rb -t second2'
    Then stdout includes "1 example"
    And stdout includes "ran test 2"
    And stdout does not include "ran test 1"
    And stdout does not include "ran test 3"

    # test_2 is tagged with second3 (consolidates metadata until they are used)
    When I run 'mrspec test/tag_test.rb -t second3'
    Then stdout includes "1 example"
    And stdout includes "ran test 2"
    And stdout does not include "ran test 1"
    And stdout does not include "ran test 3"

    # for sanity, show that test_3 is actually a test, just not tagged (metadata gets cleared)
    When I run 'mrspec test/tag_test.rb'
    Then stdout includes "3 examples"
    And stdout includes "ran test 1"
    And stdout includes "ran test 2"
    And stdout includes "ran test 3"


  Scenario: Can add metadata to groups
    Given the file "tag_groups.rb":
    """
    class Tag1Test < Minitest::Test
      classmeta tag1: true

      meta tag2: true
      def test_tagged_with_1_and_2
      end

      def test_tagged_with_1_only
      end
    end

    class UntaggedTest < Minitest::Test
      def test_untagged
      end
    end
    """

    # tag1 runs all tests in Tag1Test (b/c the tag is on the class)
    When I run 'mrspec -f d -t tag1 tag_groups.rb'
    Then the program ran successfully
    And  stdout includes "tagged with 1 and 2"
    And  stdout includes "tagged with 1 only"
    And  stdout does not include "untagged"

    # tag2 runs only Tag1Test#test_tagged_with_1_and_2 (b/c the tag is on the method)
    When I run 'mrspec -f d -t tag2 tag_groups.rb'
    Then the program ran successfully
    And  stdout includes "tagged with 1 and 2"
    And  stdout does not include "tagged with 1 only"
    And  stdout does not include "untagged"

    # no tags runs all tests (ignores all tagging)
    When I run 'mrspec -f d tag_groups.rb'
    Then the program ran successfully
    And  stdout includes "tagged with 1 and 2"
    And  stdout includes "tagged with 1 only"
    And  stdout includes "untagged"


  Scenario: Can add metadata to Minitest::Specs
    Given the file "a_spec.rb":
    """
    require 'minitest/spec'

    describe 'First' do
      classmeta runthis: true
      it('spec1') { }
    end

    class MySpec < Minitest::Spec
      meta runthis: true
      it('spec2') { }
      it('spec3') { }
      it('spec4') { }
    end

    class Wat < Minitest::Test
      extend Minitest::Spec::DSL
      register_spec_type /^Lol/, self

      def bbq
        'rofl'
      end
    end

    describe 'LolSpec!' do
      meta runthis: true
      it 'has different inheritance' do
        assert self.kind_of? Wat
      end
    end
    """
    When I run 'mrspec -t runthis a_spec.rb'
    Then the program ran successfully
    And stdout includes "3 examples"
    And stdout includes "0 failures"



  Scenario: Intelligently formats Minitest's assertions
    Given the file "test/some_assertions.rb":
    """
    RSpec.describe 'a' do
      it('fails1') { expect('rspec-1').to eq 'rspec-2' }
      it('fails2') { expect(%w[rspec a b c]).to include 'd' }
    end

    class A < Minitest::Test
      def test_fails1() assert_equal 'minitest-1', 'minitest-2' end
      def test_fails2() assert_includes %w[minitest a b c], 'd' end
    end
    """
    When I run 'mrspec --no-color test/some_assertions.rb'
    # RSpec eq
    Then stdout includes 'expected: "rspec-2"'
    And  stdout includes '     got: "rspec-1"'
    # Minitest assert_equal
    And  stdout includes 'Expected: "minitest-1"'
    And  stdout includes '  Actual: "minitest-2"'

    # RSpec includes
    And  stdout includes 'expected ["rspec", "a", "b", "c"] to include "d"'
    # Minitest assert_includes
    And  stdout includes 'Expected ["minitest", "a", "b", "c"] to include "d"'

    # Doesn't print Minitest::Assertion class, as if it's an exception
    And  stdout does not include "Minitest::Assertion"

  Scenario: Respects Minitest's lifecycle hooks
    Given the file "test/lifecycle_test.rb":
    """
    class A < Minitest::Test
      %w(before_teardown teardown after_teardown before_setup setup after_setup).shuffle.each do |methodname|
        define_method methodname do
          @order ||= []
          @order << methodname
        end
      end

      def test_1
        @order << :test_1
        at_exit { puts "[#{@order.join " "}]" }
      end

      def test_2
        @order << :test_2
        at_exit { puts "[#{@order.join " "}]" }
      end
    end
    """
    When I run "mrspec test/lifecycle_test.rb"
    Then the program ran successfully
    And  stdout includes "[before_setup setup after_setup test_1 before_teardown teardown after_teardown]"
    And  stdout includes "[before_setup setup after_setup test_2 before_teardown teardown after_teardown]"


  Scenario: Doesn't get fucked up by Minitest autorunning
    Given the file "requires_minitest_autorun.rb":
    """
    require 'minitest/autorun'
    class A < Minitest::Test
      def test_a
        p caller.last # will tell us which lib is running this test
      end
    end
    """
    When I run "mrspec requires_minitest_autorun.rb"
    Then stdout includes "rspec/core/runner.rb"
    And  stdout does not include "lib/minitest.rb"


  Scenario: Doesn't get fucked up by RSpec autorunning
    Given the file "requires_rspec_autorun.rb":
    """
    require 'rspec/autorun'

    $load_count ||= 0
    $load_count += 1

    RSpec.describe 'something' do
      it 'does whatever' do
        $run_count ||= 0
        $run_count += 1
        puts "load count: #{$load_count}"
        puts "run count:  #{$run_count}"
      end
    end
    """
    When I run "mrspec requires_rspec_autorun.rb"
    Then stdout includes "load count: 1"
    And  stdout includes "run count:  1"
    And  stdout does not include "load count: 2"
    And  stdout does not include "run count:  2"


  Scenario: Doesn't depend on RSpec::Mocks or RSpec::Expectations
    Given the file "no_dev_deps/Gemfile":
    """
    source 'https://rubygems.org'
    gem 'mrspec', path: "{{root_dir}}"
    """
    When I run "env BUNDLE_GEMFILE=no_dev_deps/Gemfile bundle install"
    Then the program ran successfully

    Given the file "no_dev_deps/print_results.rb":
    """
    at_exit do
      exception = $!
      if exception.kind_of? SystemExit
        puts "ERROR: SYSTEM EXIT (RSpec raises this if there's a failure)"
      elsif exception
        puts "AN ERROR: #{$!.inspect}"
      else
        puts "NO ERROR"
      end

      unexpected_deps = $LOADED_FEATURES.grep(/rspec/).grep(/mocks|expectations/)
      if unexpected_deps.any?
        puts "UNEXPECTED DEPS: #{unexpected_deps}"
      else
        puts "NO UNEXPECTED DEPS"
      end
    end
    """
    And the file "no_dev_deps/test_with_failures.rb":
    """
    require_relative 'print_results'
    class A < Minitest::Test
      def test_that_passes() assert_equal 1, 1 end
      def test_that_fails()  assert_equal 1, 2 end
      def test_that_errors() raise "wat"       end
      def test_that_skips()  skip              end
    end
    """

    When I run "env BUNDLE_GEMFILE=no_dev_deps/Gemfile bundle exec mrspec no_dev_deps/test_with_failures.rb"
    Then stderr is empty
    And  stdout includes "4 examples"
    And  stdout includes "2 failures"
    And  stdout includes "1 pending"
    And  stdout includes "ERROR: SYSTEM EXIT"
    And  stdout includes "NO UNEXPECTED DEPS"

    Given the file "no_dev_deps/test_that_passes.rb":
    """
    require_relative 'print_results'
    class A < Minitest::Test
      def test_that_passes() assert true end
    end
    """
    When I run "env BUNDLE_GEMFILE=no_dev_deps/Gemfile bundle exec mrspec -f p no_dev_deps/test_that_passes.rb"
    Then the program ran successfully
    And  stdout includes "NO ERROR"
    And  stdout includes "NO UNEXPECTED DEPS"


  Scenario: The help screen is custom to mrspec
    When I run "mrspec -h"
    Then stdout includes "Usage: mrspec"
    # Probably add more later


  # Only specifying the major version, so I get enough to be confident
  # but not enough to be too volatile
  Scenario: Prints mrspec, rspec, and minitest versions for --version
    When I run "mrspec --version"
    Then the program ran successfully
    And  stdout includes "mrspec     0."
    And  stdout includes "rspec-core 3."
    And  stdout includes "minitest   5."


  Scenario: Adds absolute path to `./test` to the $LOAD_PATH, if it exists
    Given the file "test/my_helper.rb" "puts 'I got loaded!'"
    And   the file "test/some_test.rb" "Dir.chdir('/') { require 'my_helper' }"
    When I run "mrspec"
    Then the program ran successfully
    And stdout includes "I got loaded!"


  Scenario: Correctly hooks up everything up to enable advanced analysis features
    Given the file "whatev.rb":
    """
    RSpec.describe 'MySpec' do
      it('whatev') do
        @abc = 123
        @abd.even?
      end
    end

    class MyTest < Minitest::Test
      def test_whatev
        @abc = 123
        @abd.even?
      end
    end
    """
    When I run 'mrspec whatev.rb'
    Then stdout includes "misspell"


  Scenario: Can invoke Minitest::Spec with line numbers (#21)
    Given the file "line_nums_spec.rb":
    """
    require 'minitest/spec'
    describe "group" do
      it "passing-example" do
        assert_equal true, true
      end
      it "failing-example" do
        assert_equal true, false
      end
    end
    """

    When I run "mrspec line_nums_spec.rb --format progress"
    Then stdout includes "2 examples, 1 failure"

    When I run "mrspec line_nums_spec.rb:3 --format progress"
    Then stdout includes "1 example, 0 failures"

    When I run "mrspec line_nums_spec.rb:6 --format progress"
    Then stdout includes "1 example, 1 failure"
