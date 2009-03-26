require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'extlib/trait'

describe Trait do
  describe "instantiated with a block" do
    it "defers block body evaluation" do
      lambda do
        Trait.new do
          raise "Will only be evaluated when mixed in"
        end
      end.should_not raise_error
    end
  end


  describe "included into hosting class" do
    before :all do
      KlazzyTrait = Trait.new do
        def self.klassy
          "Klazz"
        end

        def instancy
          "Instanzz"
        end
      end

      @klass = Class.new do
        include KlazzyTrait
      end
    end

    it "class evals block body" do
      @klass.klassy.should == "Klazz"
      @klass.new.instancy.should == "Instanzz"
    end
  end
end
