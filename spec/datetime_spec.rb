require File.dirname(__FILE__) + '/spec_helper'
require 'json'

describe DateTime, "#to_time" do
  before do
    @expected = "Wed Aug 20 02:16:06 -0700 2008"
    datetime = DateTime.parse(@expected)
  end
  
  it "should return a copy of time" do
    time = datetime.to_time
    time.class.should == Time
    time.to_s.should == @expected
  end
end

describe Time, "#to_datetime" do
  it "should return a copy of its self" do
    datetime.to_datetime.should == datetime
  end
end