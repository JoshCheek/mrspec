# Don't filter mrspec out of the backtrace when testing itslef!
RSpec.configure do |config|
  config.backtrace_formatter.exclusion_patterns.reject! do |pattern|
    pattern =~ "/mrspec/"
  end
end
