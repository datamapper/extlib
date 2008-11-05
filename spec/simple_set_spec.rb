require File.dirname(__FILE__) + '/spec_helper'

describe Extlib::SimpleSet do
  
  before do
    @s = Extlib::SimpleSet.new("Foo")
  end
  
  it "should support <<" do
    @s << "Hello"
    @s.should be_include("Hello")
  end
  
  it "should support merge" do
    @s.should have_key("Foo")
    @t = @s.merge(["Bar"])
    @t.should be_kind_of(Extlib::SimpleSet)
    @t.should have_key("Foo")
    @t.should have_key("Bar")    
  end
  
  it "should support inspect" do
    @s.inspect.should == "#<SimpleSet: {\"Foo\"}>"
  end
  
end
