require 'support/helper'

RSpec.describe "rspec can take tags to identify tests", :first do
  it "can see the tags and the correct tests will run" do
    expect(5).to eq(5)
  end
  
  it "will also see individual tags", :single do
    expect(1).to eq(1)
  end
end

RSpec.describe "will separate tests in rspec to it and describe blocks", :second do 
  it "will be able to differentiate between different blocks" do
    expect("rspec is cool").to eq("rspec is cool")
  end
end