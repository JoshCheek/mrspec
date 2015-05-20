[![Build Status](https://secure.travis-ci.org/JoshCheek/mrspec.png?branch=master)](http://travis-ci.org/JoshCheek/mrspec)

mrspec
======

Minitest and RSpec, sitting in a tree...

Runs Minitest tests using RSpec's runner.
Also runs RSpec's tests, so if you want to use them side-by-side,
this will do it.


Examples
--------

### Fail Fast and Tagging

Here, we see that we have the ability to run all the tests until one fails (the `--fail-fast` flag).
We can also add metadata to classes using `classmeta`, and individual tests using `meta`.
This allows us to do things like easily switch which tests are targeted from the command-line.

```ruby
# file: test.rb

# Here, we tag the `NoFailures` class with `them_passing_tests`
# And the `TwoFailures` class with `them_failing_tests`
class NoFailures < Minitest::Test
  classmeta them_passing_tests: true

  def test_1() end
  def test_2() end
end

class TwoFailures < Minitest::Test
  classmeta them_failing_tests: true

  # I like short tagnames, b/c usually my use is transient.
  # So I can come mark the ones I want to run, and keep running them until they're fixed.
  # The tags are correct, even if I change a test name or its position moves!
  meta f1: true
  def test_3
    raise 'first failure'
  end

  meta f2: true
  def test_4
    raise 'second failure'
  end
end
```

![Examples of Tagging](https://s3.amazonaws.com/josh.cheek/mrspec/tagging.png)


### Run specs and tests in tandem

Here, we see that it matches `test/*_test.rb`, `test/test_*.rb`, `spec/*_spec.rb`.
It picks the RSpec group name by removing leading and trailing `Test` from the class name,
it picks the example name by removing leading `test_` from the method, and switching underscores with spaces.
It finds test classes and test methods by asking Minitest (which tracks subclasses of `Minitest::Runnable`,
and asks each runnable class for its runnable methods).

```ruby
# file: spec/a_spec.rb
  RSpec.describe 'An RSpec test' do
    it('does rspec things') { }
  end

# file: test/b_test.rb
  class AMinitestTest < Minitest::Test
    def test_it_does_minitesty_things
    end
  end

# file: test/test_c.rb
  class TestSomethingElse < Minitest::Test
    def some_helper_method # won't show up
    end

    def test_this_also_does_minitesty_things
    end
  end

  # Added because Minitest::Runnable knows about it
  class AnotherTestWithNeitherThePrefixNorTheSuffix < Minitest::Test
    # This class says is_this_a_test_yes_it_is is a test, so we consider it to be one,
    # despite its deviation from the traditional naming pattern
    def self.runnables
      ['is_this_a_test_yes_it_is']
    end

    def is_this_a_test_yes_it_is
    end
  end

  # Ignored b/c Minitest::Runnable doesn't know about it
  class NotATest
    def test_whatevz
    end
  end

# file: test/d_spec.rb
  require 'minitest/spec'
  describe 'I am a minitest spec' do
    it 'does minitesty things' do
      assert_includes self.class.ancestors, Minitest::Spec
    end
  end
```

![file patterns](https://s3.amazonaws.com/josh.cheek/mrspec/file-patterns.png)


### Failures, Errors, Skips

Here, we see that it understands Minitest skips and errors/failures.
It uses the minitest messages, because they're pretty legit, no need to translate them.

```ruby
# file: various_errors.rb
class VariousErrors < Minitest::Test
  def test_this_passes()                          assert true                    end
  def test_they_arent_equal()                     assert_equal 1, 2              end
  def test_is_not_included()                      assert_includes %w[a b c], 'd' end
  def test_raises_an_error()                      raise "Blowin up ovah here!"   end
  def test_skipped_for_no_reason_in_particular()  skip                           end
  def test_skipped_because…_reasons()             skip 'and a hop'               end
end
```

I used `--format progress` here, because there's enough errors that my default documentation
formatter makes it spammy >.<

![various errors](https://s3.amazonaws.com/josh.cheek/mrspec/various-errors.png)



Why?
----

That rakefile thing is bullshit.
(find that rant I wrote)
(both the RSpec one, and the Minitest one just shell out anyway)
(I shouldn't need to add a dep on Rake just to have it call a method)
(difficulty getting minitest to run just the ones I want)


Nuances
-------

Changes the default pattern to look for any files suffixed with `_test.rb` or `_spec.rb`, or prefixed with `test_`
(RSpec, by itself, only looks for suffixes of `_spec.rb`).

Changes the default search directories to be `test` and `spec`
(RSpec, by itself, only looks in `spec`).

Turns off monkey patching, so you cannot use RSPec's toplevel describe, or `should`.
There are 2 reasons for this:

1. It conflicts with `Minitest::Spec`'s definition of `Kernel#describe`
   ([here](https://github.com/seattlerb/minitest/blob/f1081566ec6e9e391628bde3a26fb057ad2576a8/lib/minitest/spec.rb#L71)).
   And must be preemptively turned off, because after-the-fact disabling
   causes it to be undefined on both `main` and `Module` ([here](https://github.com/rspec/rspec-core/blob/3145e2544e1825bc754d0986e893664afe19abf5/lib/rspec/core/dsl.rb#L72)),
   which means that even if you don't use it, it will still interfere with `Minitest::Spec`
   (removing methods allows method lookup to find superclass definitions,
   but undefining them ends method lookup.)
2. You should just not do that in general. Monkey patching is a bad plan, all around,
   just use the namespaced methods, or create your own methods to wrap the assertion syntax.
   I'm looking forward to when this feature is removed altogether.


Running the tests
-----------------

```sh
$ bundle
$ bundle exec cucumber
```

Why are all the tests written in Cucumber?
Well... mostly just b/c I initially wrote this as a script for my dotfiles,
which I mostly test with Cucumber and [Haiti](https://github.com/JoshCheek/haiti),
as they are usually heavily oriented towards integration,
and often not written in Ruby.


Attribution
-----------

Idea from [e2](https://github.com/e2), proposed [here](https://github.com/rspec/rspec-core/issues/1786).
Iniitial code was based off of [this gist](https://gist.github.com/e2/bcd2be81b4ac28c85ea0)


MIT License
-----------

```
Copyright (c) 2015 Josh Cheek

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
