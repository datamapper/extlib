require File.dirname(__FILE__) + '/spec_helper'

describe Extlib::SimpleSet do

  before do
    @s = Extlib::SimpleSet.new("Foo")
  end

  it "should support <<" do
    @s << "Hello"
    @s.to_a.should include("Hello")
  end

  it "should support merge" do
    @s.should have_key("Before merge")
    @t = @s.merge(["Merged value"])
    @t.should be_kind_of(Extlib::SimpleSet)
    @t.should have_key("Before merge")
    @t.should have_key("Merged value")
  end

  it "should support inspect" do
    @s.inspect.should == "#<SimpleSet: {\"Foo\"}>"
  end
end
