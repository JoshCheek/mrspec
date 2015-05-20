module MRspec
  # With assertions, we must wrap it in a class that has "RSpec" in the name
  #   https://github.com/rspec/rspec-core/blob/3145e2544e1825bc754d0986e893664afe19abf5/lib/rspec/core/formatters/exception_presenter.rb#L94
  #   This is how RSpec differentiates failures from exceptions (errors get their class printed, failures do not)
  #   We could wrap it in an ExpectationNotMetError, as all their errors seem to be,
  #   but that is defined in rspec-expectations, which we otherwise don't depend on.
  #
  # We'll keep the Minitest error messages, though, as they were on par with RSpec's for all the examples I tried
  class MinitestAssertionForRSpec < Exception
    def initialize(assertion)
      super assertion.message
      set_backtrace assertion.backtrace
    end
  end
end
