require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Module do

  before(:all) do
    module Foo
      module Bar
        module Noo
          module Too
          end
        end
      end

      class Zed
      end
    end

    class Baz
    end

    class Bar
    end
  end

  it "should not find a constant" do
    Object::find_const('MissingConstant').should == nil
  end

  it "should be able to get a recursive constant" do
    Object::find_const('Foo::Bar').should == Foo::Bar
  end

  it "should ignore get Constants from the Kernel namespace correctly" do
    Object::find_const('::Foo::Bar').should == ::Foo::Bar
  end

  it "should not cache unresolvable class string" do
    lambda { find_const('Foo::Bar::Baz') }.should raise_error(NameError)
    Object::send(:__nested_constants__).has_key?('Foo::Bar::Baz').should == false
  end

  it "should find relative constants" do
    Foo.find_const('Bar').should == Foo::Bar
    Foo.find_const('Baz').should == Baz
  end

  it "should find sibling constants" do
    Foo::Bar.find_const("Zed").should == Foo::Zed
  end

  it "should find nested constants on nested constants" do
    # pending "Implement this"
    Foo::Bar.find_const('Noo::Too')
  end

end
