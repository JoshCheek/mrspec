require 'minitest/spec'

class TestParserMonkeyPatches < Minitest::Spec
  Parser = RSpec::Core::Parser

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
    def options
      @options ||= {}
    end

    def mrspec_option_parser
      @mrspec_option_parser ||= Parser.new.mrspec_parser options
    end

    def rspec_option_parser
      @rspec_option_parser ||= Parser.new.rspec_parser options
    end

    def record_version(option_parser, flag)
      stdout, stderr, *rest = capture_io do
        begin option_parser.parse([flag])
        rescue SystemExit
        end
      end
      assert_empty rest
      assert_empty stderr
      stdout
    end

    it 'returns the original #rspec_parser' do
      # just showing that it does RSpec parsery things
      mrspec_option_parser.parse ['-I', 'somepath']
      assert_equal options[:libs], ['somepath']
    end

    it 'modifies the description to replace uses of rspec with uses of mrpspec' do
      assert_match /\bmrspec\b/, mrspec_option_parser.banner
      refute_match /\brspec\b/,  mrspec_option_parser.banner
    end

    it 'overrides -v and --version includes the Mrspec version, the RSpec::Core version, and the Minitest version' do
      rspec_version  = record_version Parser.new.rspec_parser({}),  '--version'
      rspec_v        = record_version Parser.new.rspec_parser({}),  '-v'
      mrspec_version = record_version Parser.new.mrspec_parser({}), '--version'
      mrspec_v       = record_version Parser.new.mrspec_parser({}), '-v'

      # RSpec version parser defines both of these flags to return its version
      assert_equal rspec_version, rspec_v
      assert_equal RSpec::Core::Version::STRING, rspec_version.chomp

      # MRspec overrides both of these flags to print versions of all relevant libs
      expected = "mrspec     #{MRspec::VERSION}\n"\
                 "rspec-core #{RSpec::Core::Version::STRING}\n"\
                 "minitest   #{Minitest::VERSION}\n"
      assert_equal mrspec_version, mrspec_v
      assert_equal expected, mrspec_version
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
    assert_match /\brspec\b/, Parser.new.parser({}).banner

    Parser.parser_method = mrspec_parser
    assert_match /\bmrspec\b/, Parser.new.parser({}).banner
  end
end
