mrspec
======

Minitest and RSpec, sitting in a tree...

Runs Minitest tests using RSpec's runner.
Also runs RSpec's tests, so if you want to use them side-by-side,
this will do it.


Examples
--------

* [Autoloads specs and tests](https://github.com/JoshCheek/dotfiles/blob/7495046fbe4a927394558e7da43b07219b02594f/test/mrspec.feature#L9)
* [Fail fast](https://github.com/JoshCheek/dotfiles/blob/7495046fbe4a927394558e7da43b07219b02594f/test/mrspec.feature#L109)
* [Tagging tests](https://github.com/JoshCheek/dotfiles/blob/7495046fbe4a927394558e7da43b07219b02594f/test/mrspec.feature#L181)
* [Tagging classes](https://github.com/JoshCheek/dotfiles/blob/4c5bf2948a5f1d850e9d33311d1bea139e80c7ba/test/mrspec.feature#L240)


Why?
----

That rakefile thing is bullshit.
(find that rant I wrote)
(both the RSpec one, and the Minitest one just shell out anyway)
(I shouldn't need to add a dep on Rake just to have it call a method)
(difficulty getting minitest to run just the ones I want)


Nuances
-------

Changes the default pattern to look for any files suffixed with `_test.rb` and `_spec.rb`
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
