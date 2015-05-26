require 'rspec/core/option_parser'

class RSpec::Core::Parser
  # Trying to mitigate the invasiveness of this code.
  # It's not great, but it's better than unconditionally overriding the method.
  # We have to do this, b/c OptionParser will print directly to stdout/err
  # and call `exit`: https://gist.github.com/JoshCheek/7adc25a46e735510558d
  # The RSpec portion does this, too https://github.com/rspec/rspec-core/blob/3145e2544e1825bc754d0986e893664afe19abf5/lib/rspec/core/option_parser.rb#L267-299
  # so we need to get between the definition and the parsing to make any changes

  # Save RSpec's parser
  alias rspec_parser parser

  # Ours calls RSpec's, then modifies values on the returned parser
  def mrspec_parser(*args, &b)
    option_parser = rspec_parser(*args, &b)

    # update the program name
    option_parser.banner.gsub! /\brspec\b/, 'mrspec'

    # print mrspec version, and dependency versions
    option_parser.on('-v', '--version', 'Display the version.') do
      puts "mrspec     #{MRspec::VERSION}\n"\
           "rspec-core #{RSpec::Core::Version::STRING}\n"\
           "minitest   #{Minitest::VERSION}\n"
      exit
    end

    option_parser
  end

  # A place to store which method `parser` actually resolves to
  singleton_class.class_eval { attr_accessor :parser_method }

  # Default it to RSpec's, because requiring this file shouldn't fuck up your environment,
  # We'll swap the value in the binary, that decision belongs as high in the callstack as we can get it.
  self.parser_method = instance_method :rspec_parser

  # The actual parser method just delegates to the saved one (ultra-late binding :P)
  define_method :parser do |*args, &b|
    self.class.parser_method.bind(self).call(*args, &b)
  end
end
