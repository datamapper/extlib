require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Mash do
  before(:each) do
    @hash = { "mash" => "indifferent", :hash => "different" }
  end
  
  describe "#initialize" do
    it 'converts all keys into strings when param is a Hash' do
      mash = Mash.new(@hash)

      mash.keys.any? { |key| key.is_a?(Symbol) }.should be(false)
    end

    it 'converts all Hash values into Mashes if param is a Hash' do
      mash = Mash.new :hash => @hash

      mash.should be_an_instance_of(Mash)
      # sanity check
      mash["hash"]["hash"].should == "different"
    end

    it 'delegates to superclass constructor if param is not a Hash' do
      mash = Mash.new("dash berlin")

      mash["unexisting key"].should == "dash berlin"
    end
  end # describe "#initialize"


  
  describe "#key?" do
    before(:each) do
      @mash = Mash.new(@hash)
    end
    
    it 'converts key before lookup' do
      @mash.key?("mash").should be(true)
      @mash.key?(:mash).should be(true)

      @mash.key?("hash").should be(true)
      @mash.key?(:hash).should be(true)

      @mash.key?(:rainclouds).should be(false)
      @mash.key?("rainclouds").should be(false)
    end

    it 'is aliased as include?' do
      @mash.include?("mash").should be(true)
      @mash.include?(:mash).should be(true)

      @mash.include?("hash").should be(true)
      @mash.include?(:hash).should be(true)

      @mash.include?(:rainclouds).should be(false)
      @mash.include?("rainclouds").should be(false)
    end

    it 'is aliased as member?' do
      @mash.member?("mash").should be(true)
      @mash.member?(:mash).should be(true)

      @mash.member?("hash").should be(true)
      @mash.member?(:hash).should be(true)

      @mash.member?(:rainclouds).should be(false)
      @mash.member?("rainclouds").should be(false)
    end
    
  end # describe "#key?"
end
