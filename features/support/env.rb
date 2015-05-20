require 'haiti'
require 'tmpdir'
require 'fileutils'

proving_grounds_dir = Dir.mktmpdir
After { FileUtils.remove_entry proving_grounds_dir }

Haiti.configure do |config|
  config.proving_grounds_dir = proving_grounds_dir
  config.bin_dir             = File.expand_path('../../../bin', __FILE__)
end

module GeneralHelpers
  def pwd
    Haiti.config.proving_grounds_dir
  end

  def root_dir
    @root_dir ||= File.expand_path '../../..', __FILE__
  end
end

When 'I pry' do
  require "pry"
  binding.pry
end

Then 'the program ran successfully' do
  expect(@last_executed.stderr).to eq ""
  expect(@last_executed.exitstatus).to eq 0
end
