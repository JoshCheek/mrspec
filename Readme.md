[![Build Status](https://secure.travis-ci.org/JoshCheek/mrspec.png?branch=master)](http://travis-ci.org/JoshCheek/mrspec)

mrspec
======

Minitest and RSpec, sitting in a tree, T. E. S. T. I. N. G!

Runs Minitest tests using RSpec's runner.
Also runs RSpec's tests, so if you want to use them side-by-side,
this will do it.


Examples
--------


### Run specs and tests in tandem

It matches `test/*_test.rb`, `test/test_*.rb`, `spec/*_spec.rb`.
The RSpec group description is the class name without `Test` prefix/suffix.
The example name is the method name without the `test_` prefix,
and with underscores switched to spaces.
It finds test classes and test methods by asking Minitest what it is tracking.

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
    # This causes Minitest to consider it a test, so we consider it one
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

It understands Minitest skips and errors/failures.

```ruby
# file: various_errors.rb
class VariousErrors < Minitest::Test
  def test_this_passes()              assert true                    end
  def test_they_arent_equal()         assert_equal 1, 2              end
  def test_is_not_included()          assert_includes %w[a b c], 'd' end
  def test_skipped_because…_reasons() skip                           end
end
```

I used `--format progress` here, because there's enough errors that my default documentation
formatter makes it spammy >.<

![various errors](https://s3.amazonaws.com/josh.cheek/mrspec/various-errors2.png)


### Fail Fast and filtering

The `--fail-fast` flag is a favourite of mine. It continues running tests until it sees a failure, then it stops.

We can also use tags to filter which tests to run.
Mrspec adds RSpec metadata to Minitest classes and tests,
the metadata behaves as a tag.

The best thing about tags is they're easy to add,
and they continue to apply to the same test, when it moves around
(line numbers change), They stay correct even if I rename it!
I won't have to tweak my command-line invocation until I've got the test passing!


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
  # I just keep them around until they're fixed.
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


Default configuration
---------------------

You can place a file named `.rspec` in your home directory with command-line arguments in it.
These will be used as defaults when you run `mrspec` or `rspec`.
[Here](https://github.com/JoshCheek/dotfiles/blob/5948132cd2367ef3b86fd2ce5351948a65d7aec7/rspec) is mine.


Why?
----

The default way to run minitest tests is with Rake.
And if you have multiple suites, that can be nice,
or if you already use Rake, then it's not adding a new dependency.
But here are some frustrations I have with it as a test runner:

1. I don't want to add a dependency on Rake, unless I need it.
1. The `Rake::TestTask` is difficult to make sense of.
1. The Rake tasks ultimately just shell out ([RSpec's](https://github.com/rspec/rspec-core/blob/3145e2544e1825bc754d0986e893664afe19abf5/lib/rspec/core/rake_task.rb#L70),
   [Minitest's](https://github.com/ruby/rake/blob/e644af3a09659c7e04245186607091324d8816e9/lib/rake/testtask.rb#L104)).
   So I don't see what they offer over invoking the program directly (usually I know what I want to pass the program,
   and I am trying to figure out how to configure the test task to do that).
   The overhead of running additional processes can also be high:
   think how long Rails takes to start up, now imagine paying that twice every time you want to run your tests!
1. It makes it difficult to dynamically alter my test invoation.
   With Minitest, you can pass `-n test_something` and it will only run the test named `test_something`,
   but now I have to edit code tomake that happen.

Furthermore, if someone doesn't know about the test task, or it seems formidable, as it often does to new students
(I'm a [teacher](http://turing.io/team)), then they won't use it. They instead run files one at a time.
When I go to run the tests, they don't have a way to run all of them.
This overhead, in turn, disinclines them to run the tests,
such that they may be failing and not realize it.

Anyway, all of this is to say that Minitest needs a runner.
I hear Rails is working on one, but I don't know when that'll be available,
or if it will be written in a way that it can be used outside of Rails.

But the RSpec runner is very nice, it has a lot of features that I use frequently.
Someone suggested running Minitest with the RSpec runner (see attribution section),
and I thought that was an interesting idea that could have value if it worked.
...so, here we are.

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

Only expected to support Rubies in the [.travis.yml](https://github.com/JoshCheek/mrspec/blob/fa1945d3d4941a90a3272020b51468dfb42f8212/.travis.yml).


Running the tests
-----------------

```sh
$ bundle
$ bundle exec bin/mrspec
$ bundle exec cucumber
```

Why are all the tests written in Cucumber?
Well... mostly just b/c I initially wrote this as a script for my dotfiles,
which I mostly test with Cucumber and [Haiti](https://github.com/JoshCheek/haiti),
as they are usually heavily oriented towards integration,
and often not written in Ruby.

What about the `test` directory?
I decided to describe all the behaviour that can be unit tested,
but haven't taken the time to implement most of them yet,
because I don't currently have any features I'm trying to add.
As I maintain this, though, I'll begin implementing them,
as it will be easier in the end :)


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
