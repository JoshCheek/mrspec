require 'rspec/core/option_parser'

class RSpec::Core::Parser
  # It calls `exit` from within the parser,
  # so we have to do this crazy to get at it.
  # Aside: https://gist.github.com/JoshCheek/7adc25a46e735510558d
  original_parser = instance_method(:parser)
  define_method :parser do |*args, &b|
    original_parser.bind(self).call(*args, &b).tap { |parser| parser.banner.gsub! /\brspec\b/, 'mrspec' }
  end
end
