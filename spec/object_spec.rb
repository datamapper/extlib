require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module HactiveSupport
  class MemoizeConsideredUseless
  end
end

class SymbolicDuck
  def quack
  end
end

class ClassyDuck
end

describe Object do

  describe "#full_const_get" do
    it 'returns constant by FQ name in receiver namespace' do
      Object.full_const_get("Extlib").should == Extlib
      Object.full_const_get("Extlib::SimpleSet").should == Extlib::SimpleSet
    end
  end

  describe "#full_const_set" do
    it 'sets constant value by FQ name in receiver namespace' do
      Object.full_const_set("HactiveSupport::MCU", HactiveSupport::MemoizeConsideredUseless)
      
      Object.full_const_get("HactiveSupport::MCU").should == HactiveSupport::MemoizeConsideredUseless
      HactiveSupport.full_const_get("MCU").should == HactiveSupport::MemoizeConsideredUseless
    end
  end

  describe "#make_module" do
    it 'creates a module from string FQ name' do
      Object.make_module("Milano")
      Object.make_module("Norway::Oslo")

      defined?(Milano).should == "constant"
      defined?(Norway::Oslo).should == "constant"
    end
  end


  describe "#quacks_like?" do
    it 'returns true if duck is a Symbol and receiver responds to it' do
      SymbolicDuck.new.quacks_like?(:quack).should be(true)
    end

    it 'returns false if duck is a Symbol and receiver DOES NOT respond to it' do
      SymbolicDuck.new.quacks_like?(:wtf).should be(false)
    end

    it 'returns true if duck is a class and receiver is its instance' do
      receiver = ClassyDuck.new
      receiver.quacks_like?(ClassyDuck).should be(true)
    end

    it 'returns false if duck is a class and receiver IS NOT its instance' do
      receiver = ClassyDuck.new
      receiver.quacks_like?(SymbolicDuck).should be(false)
    end

    it 'returns true if duck is an array and at least one of its members quacks like this duck' do
      receiver = ClassyDuck.new
      ary      = [ClassyDuck, SymbolicDuck]
      
      receiver.quacks_like?(ary).should be(true)
    end

    it 'returns false if duck is an array and none of its members quacks like this duck' do
      receiver = ClassyDuck.new
      ary      = [SymbolicDuck.new, SymbolicDuck]
      
      receiver.quacks_like?(ary).should be(false)
    end    
  end
end
