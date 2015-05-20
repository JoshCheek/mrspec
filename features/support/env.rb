require 'haiti'

Haiti.configure do |config|
  config.proving_grounds_dir = File.expand_path '../../../proving_grounds', __FILE__
  config.bin_dir             = File.expand_path '../../../bin',             __FILE__
end

module GeneralHelpers
  def pwd
    Haiti.config.proving_grounds_dir
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
