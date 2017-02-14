require 'minitest/spec'
require 'support/helper'

class TestParserMonkeyPatches < Minitest::Spec
  Parser = RSpec::Core::Parser
  ConfigurationOptions = RSpec::Core::ConfigurationOptions

  def rspec_parser
    Parser.instance_method :rspec_parser
  end

  def mrspec_parser
    Parser.instance_method :mrspec_parser
  end

  it 'can get the original rspec parser with #rspec_parser' do
    filename, _linenum = rspec_parser.source_location
    assert_includes filename, '/lib/rspec/core/'
    refute_includes filename, '/lib/mrspec/'
  end

  it 'has an overridden parser with #mrspec_parser' do
    mrspec_parser = Parser.instance_method :mrspec_parser
    filename, _linenum = mrspec_parser.source_location
    refute_includes filename, '/lib/rspec/core/'
    assert_includes filename, '/lib/mrspec/'
  end

  describe '#mrspec_parser' do
    def record_hostile_parsing(parser_method_name, flag)
      # This is performed by Runner.run
      original_parser_method = Parser.parser_method
      Parser.parser_method   = Parser.instance_method parser_method_name
      options = ConfigurationOptions.new([])
      result  = Parser.parse([flag])
      stderr  = StringIO.new
      stdout  = StringIO.new
      result[:runner].call(options, stderr, stdout)
      assert_empty stderr.string
      stdout.string
    ensure
      Parser.parser_method = original_parser_method
    end

    it 'returns the original #rspec_parser' do
      # just showing that it does RSpec parsery things
      options = {}
      Parser.new([]).mrspec_parser(options).parse(['-I', 'somepath'])
      assert_equal options[:libs], ['somepath']
    end

    it 'modifies the description to replace uses of rspec with uses of mrpspec' do
      assert_match /\bmrspec\b/, Parser.new([]).mrspec_parser({}).banner
      refute_match /\brspec\b/,  Parser.new([]).mrspec_parser({}).banner
    end

    it 'overrides -v and --version includes the Mrspec version, the RSpec::Core version, the Minitest version, and the ErrorToCommunicate version' do
      rspec_version  = record_hostile_parsing :rspec_parser,  '--version'
      rspec_v        = record_hostile_parsing :rspec_parser,  '-v'
      mrspec_version = record_hostile_parsing :mrspec_parser, '--version'
      mrspec_v       = record_hostile_parsing :mrspec_parser, '-v'

      # RSpec version parser defines both of these flags to return its version
      assert_equal rspec_version, rspec_v
      assert_equal RSpec::Core::Version::STRING, rspec_version.chomp

      # MRspec overrides both of these flags to print versions of all relevant libs
      expected = "mrspec     #{MRspec::VERSION}\n"\
                 "rspec-core #{RSpec::Core::Version::STRING}\n"\
                 "minitest   #{Minitest::VERSION}\n"\
                 "wwhhiae2c  #{ErrorToCommunicate::VERSION}\n"
      assert_equal mrspec_version, mrspec_v
      assert_equal expected, mrspec_version
    end

    # Giving up on making sure these are equivalent, it's not the end of the world if they aren't
    # I'm basically at a point where I think that no one should use OptionParser
    it 'sets the correct description for the versions'

    it 'includes the what_weve_got_here_is_an_error_to_communicate formatter in the help screen' do
      help       = record_hostile_parsing :mrspec_parser, '--help'
      formatters = help.lines
                       .drop_while { |l| l !~ /--format/ }
                       .drop(1)
                       .take_while { |l| l =~ /^\s*\[/ }
      refute_empty formatters
      indentation, initials = formatters.map { |formatter_line|
                                [formatter_line[/^\s*/].length,
                                 formatter_line[/\[.\]/]
                                ]
                              }.transpose
      first_indentation = indentation.first
      indentation.each { |i| assert_equal first_indentation, i }
      assert_equal '[w]', initials.first
    end
  end

  it 'stores the current parser in .parser_method' do
    Parser.parser_method = rspec_parser
    assert_equal Parser.parser_method, rspec_parser
    refute_equal Parser.parser_method, mrspec_parser

    Parser.parser_method = mrspec_parser
    refute_equal Parser.parser_method, rspec_parser
    assert_equal Parser.parser_method, mrspec_parser
  end

  it 'redefines #parser to use the parser in .parser_method' do
    # have to do it a bit roundabout, b/c OptionParser does not override #==, so it uses object equality
    Parser.parser_method = rspec_parser
    assert_match /\brspec\b/, Parser.new([]).parser({}).banner

    Parser.parser_method = mrspec_parser
    assert_match /\bmrspec\b/, Parser.new([]).parser({}).banner
  end
end
