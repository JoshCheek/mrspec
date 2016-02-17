require 'support/helper'

class TestFormatterConfiguration < Minitest::Spec
  def formatters_are!(*formatters, &block)
    config = MRspec::Configuration.new
    block.call config
    assert_equal formatters, config.formatters.map(&:class)
  end

  it 'defaults to WhatWeveGotHereIsAnErrorToCommunicate::RSpecFormatter' do
    refute_equal RSpec::Core::Configuration.new.default_formatter,
                 WhatWeveGotHereIsAnErrorToCommunicate::RSpecFormatter

    assert_equal MRspec::Configuration.new.default_formatter,
                 WhatWeveGotHereIsAnErrorToCommunicate::RSpecFormatter
  end


  it 'doesn\'t fuck up the normal formatter selection' do
    formatters_are! RSpec::Core::Formatters::ProgressFormatter do |config|
      config.add_formatter 'p'
    end
  end


  it 'can be specified with "--format w" and "--format what<anything>"' do
    formatters_are! WhatWeveGotHereIsAnErrorToCommunicate::RSpecFormatter do |config|
      config.add_formatter 'what'
    end

    formatters_are! WhatWeveGotHereIsAnErrorToCommunicate::RSpecFormatter do |config|
      config.add_formatter 'whatever'
    end

    assert_raises ArgumentError, /\bwha\b/ do
      MRspec::Configuration.new.add_formatter 'wha'
    end
  end
end

class TestOtherConfiguration < Minitest::Spec
  def assert_colour(is_enabled, argv)
    config = MRspec::Configuration.new
    RSpec::Core::ConfigurationOptions.new(argv).configure(config)
    assert_equal is_enabled, config.color_enabled?
  end

  it 'defaults colour to on' do
    assert_colour true, []
  end

  it 'respects explicit choices to set colour off/on' do
    assert_colour true,  ['--colour']
    assert_colour false, ['--no-colour']
  end
end
