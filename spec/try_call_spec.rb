require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe "#try_call" do
  describe "with an Object" do
    before :all do
      @receiver = Object.new
    end

    it "returns receiver itself" do
      @receiver.try_call.should == @receiver
    end
  end

  describe "with a number" do
    before :all do
      @receiver = 42
    end

    it "returns receiver itself" do
      @receiver.try_call.should == @receiver
    end
  end

  describe "with a String" do
    before :all do
      @receiver = "Ruby, programmer's best friend"
    end

    it "returns receiver itself" do
      @receiver.try_call.should == @receiver
    end
  end

  describe "with a hash" do
    before :all do
      @receiver = { :functional_programming => "FTW" }
    end

    it "returns receiver itself" do
      @receiver.try_call.should == @receiver
    end
  end

  describe "with a Proc" do
    before :all do
      @receiver = Proc.new { 5 * 7 }
    end

    it "returns result of calling of a proc" do
      @receiver.try_call.should == 35
    end
  end
end
