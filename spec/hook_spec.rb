require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Hook do
  
  before(:each) do
    @module = Module.new do
      def greet; greetings_from_module; end;
    end
    
    @class = Class.new do
      include Hook
      
      def hookable; end;
      def self.clakable; end;
      def ambiguous; hi_mom!; end;
      def self.ambiguous; hi_dad!; end;
    end
    
    @another_class = Class.new do
      include Hook
    end
    
    @class.register_instance_hooks :hookable
    @class.register_class_hooks :clakable
  end
  
  describe "hookable method registration" do
    
    describe "for class methods" do
      
      it "should already have clakable registered as a hookable method" do
        @class.class_hooks[:clakable].should_not be_nil
      end
      
      it "shouldn't confuse instance method hooks and class method hooks" do
        @class.register_instance_hooks :ambiguous
        @class.register_class_hooks :ambiguous

        @class.should_receive(:hi_dad!)
        @class.ambiguous
      end
      
      it "should not allow double registration"
      
    end
    
    describe "for instance methods" do
      
      it "should already have hookable registered as a hookable method" do
        @class.instance_hooks[:hookable].should_not be_nil
      end
      
      it "shouldn't confuse instance method hooks and class method hooks" do
        @class.register_instance_hooks :ambiguous
        @class.register_class_hooks :ambiguous

        inst = @class.new
        inst.should_receive(:hi_mom!)
        inst.ambiguous
      end
      
      it "should not allow double registration"
      
    end
    
    it "should install the block under the before hook for the appropriate method" do
      @class.before(:hookable) { }
      @class.instance_hooks[:hookable][:before].should have(1).item
    end
    
    it "should install the block under the after hook for the appropriate method" do
      @class.after(:hookable) { }
      @class.instance_hooks[:hookable][:after].should have(1).item
    end
    
    it "should save the class that the hook is registered in" do
      @class.before(:hookable) { }
      @class.instance_hooks[:hookable][:in].should == @class
    end
    
    it "should keep the parent class as the class that has the hookable method registered in" do
      @class.before(:hookable) { }
      @child = Class.new(@class)
      @child.instance_hooks[:hookable][:in].should == @class
      
      @another_child = Class.new(@class)
      @another_child.before(:hookable) { }
      @another_child.instance_hooks[:hookable][:in].should == @class
    end
    
    it "should keep separate hook hashes for separate parent models" do
      @another_class.instance_hooks.should_not == @class.instance_hooks
      Class.new(@class).instance_hooks.should == @class.instance_hooks
    end
    
    it "should be able to register multiple hookable methods at once" do
      %w(method_one method_two method_three).each do |method|
        @another_class.send(:define_method, method) {}
      end
      
      @another_class.register_instance_hooks :method_one, :method_two, :method_three
      @another_class.instance_hooks.keys.should include(:method_one)
      @another_class.instance_hooks.keys.should include(:method_two)
      @another_class.instance_hooks.keys.should include(:method_three)
    end
    
    it "should not allow a method that does not exist to be registered as hookable" do
      lambda { @another_class.register_instance_hooks :method_one }.should raise_error(ArgumentError)
    end
    
    it "should allow hooks to be registered on included module methods" do
      @class.send(:include, @module)
      @class.register_instance_hooks :greet
      @class.instance_hooks[:greet].should_not be_nil
    end
    
    it "should allow modules to register hooks in the self.included method" do
      @module.class_eval do
        def self.included(base)
          base.register_instance_hooks :greet
        end
      end
      @class.send(:include, @module)
      @class.instance_hooks[:greet].should_not be_nil
    end
    
    it "should be able to register protected methods as hooks"
    
    it "should not be able to register private methods as hooks"
  end
  
  describe "hook invocation" do
    
    describe "for class methods" do
      it 'should run an advice block' do
        @class.before_class_method(:clakable) { hi_mom! }
        @class.should_receive(:hi_mom!)
        @class.clakable
      end
      
      it 'should run an advice method' do
        @class.class_eval %{def self.before_method; hi_mom!; end;}
        @class.before_class_method(:clakable, :before_method)
        
        @class.should_receive(:hi_mom!)
        @class.clakable
      end
      
      it 'should run an advice block when the class is inherited' do
        @class.before_class_method(:clakable) { hi_mom! }
        @child = Class.new(@class)
        @child.should_receive(:hi_mom!)
        @child.clakable
      end
      
      it 'should run an advice block on child class when hook is registered in parent after inheritance' do
        @child = Class.new(@class)
        @class.before_class_method(:clakable) { hi_mom! }
        @child.should_receive(:hi_mom!)
        @child.clakable
      end
      
      it 'should be able to declare advice methods in child classes' do
        @class.class_eval %{def self.before_method; hi_dad!; end;}
        @class.before_class_method(:clakable, :before_method)

        @child = Class.new(@class) do
          def self.child; hi_mom!; end;
          before_class_method(:clakable, :child)
        end

        @child.should_receive(:hi_dad!).once.ordered
        @child.should_receive(:hi_mom!).once.ordered
        @child.clakable
      end

      it "should not execute hooks added in the child classes when in the parent class" do
        @child = Class.new(@class) { def self.child; hi_mom!; end; }
        @child.before_class_method(:clakable, :child)
        @class.should_not_receive(:hi_mom!)
        @class.clakable
      end

      it "should not overwrite methods included by extensions after the hook is declared" do
        @module.class_eval do
          @another_module = Module.new do
            def greet; greetings_from_another_module; super; end;
          end
          
          def self.extended(base)
            base.before_class_method(:clakable, :greet)
            base.extend(@another_module)
          end
        end
        
        @class.extend(@module)
        @class.should_receive(:greetings_from_another_module).once.ordered
        @class.should_receive(:greetings_from_module).once.ordered
        @class.clakable
      end

      it 'should not call the hook stack if the hookable method is overwritten and does not call super' do
        @class.before_class_method(:clakable) { hi_mom! }
        @child = Class.new(@class) do
          def self.clakable; end;
        end
        
        @child.should_not_receive(:hi_mom!)
        @child.clakable
      end

      it 'should not call hooks defined in the child class for a hookable method in a parent if the child overwrites the hookable method without calling super' do
        @child = Class.new(@class) do
          before_class_method(:clakable) { hi_mom! }
          def self.clakable; end;
        end

        @child.should_not_receive(:hi_mom!)
        @child.clakable
      end

      it 'should not call hooks defined in child class even if hook method exists in parent' do
        @class.class_eval %{def self.hello_world; hello_world!; end;}
        @child = Class.new(@class) do
          before_class_method(:clakable, :hello_world)
        end

        @class.should_not_receive(:hello_world!)
        @class.clakable
      end

      it 'should pass the hookable method arguments to the hook method' do
        @class.class_eval %{def self.hook_this(word); end;}
        @class.class_eval %{def self.before_hook_this(word); word_up(word); end;}
        @class.register_class_hooks(:hook_this)
        @class.before_class_method(:hook_this, :before_hook_this)

        @class.should_receive(:word_up).with("omg")
        @class.hook_this("omg")
      end
      
      it 'should allow the use of before and after together'
      
      it "should allow advising methods ending in ? or !" do
        @class.class_eval do
          def self.hookable!; two! end;
          def self.hookable?; three! end;
          register_class_hooks :hookable!, :hookable?
        end
        @class.before_class_method(:hookable!) { one! }
        @class.after_class_method(:hookable?) { four! }

         @class.should_receive(:one!).once.ordered
         @class.should_receive(:two!).once.ordered
         @class.should_receive(:three!).once.ordered
         @class.should_receive(:four!).once.ordered

         @class.hookable!
         @class.hookable?
      end
      
      it "should allow advising methods ending in ?, ! or = when passing methods as advices"
    end
    
    describe "for instance methods" do
      it 'should run an advice block' do
        @class.before(:hookable) { hi_mom! }

        inst = @class.new
        inst.should_receive(:hi_mom!)
        inst.hookable
      end
      
      it 'should run an advice method' do
        @class.send(:define_method, :before_method) { hi_mom! }
        @class.before(:hookable, :before_method)

        inst = @class.new
        inst.should_receive(:hi_mom!)
        inst.hookable
      end
      
      it 'should run an advice block when the class is inherited' do
        @inherited_class = Class.new(@class)
        @class.before(:hookable) { hi_dad! }

        inst = @inherited_class.new
        inst.should_receive(:hi_dad!)
        inst.hookable
      end
      
      it 'should run an advice block on child class when hook is registered in parent after inheritance' do
        @child = Class.new(@class)
        @class.before(:hookable) { hi_mom! }
        
        inst = @child.new
        inst.should_receive(:hi_mom!)
        inst.hookable
      end
      
      it 'should be able to declare advice methods in child classes' do
        @class.send(:define_method, :before_method) { hi_dad! }
        @class.before(:hookable, :before_method)

        @child = Class.new(@class) do
          def child; hi_mom!; end;
          before :hookable, :child
        end

        inst = @child.new
        inst.should_receive(:hi_dad!).once.ordered
        inst.should_receive(:hi_mom!).once.ordered
        inst.hookable
      end

      it "should not execute hooks added in the child classes when in parent class" do
        @child = Class.new(@class)
        @child.send(:define_method, :child) { hi_mom! }
        @child.before(:hookable, :child)

        inst = @class.new
        inst.should_not_receive(:hi_mom!)
        inst.hookable
      end

      it 'should not overwrite methods included by modules after the hook is declared' do
        @module.class_eval do
          @another_module = Module.new do
            def greet; greetings_from_another_module; super; end;
          end

          def self.included(base)
            base.before(:hookable, :greet)
            base.send(:include, @another_module)
          end
        end

        @class.send(:include, @module)

        inst = @class.new
        inst.should_receive(:greetings_from_another_module).once.ordered
        inst.should_receive(:greetings_from_module).once.ordered
        inst.hookable
      end
      
      it 'should not call the hook stack if the hookable method is overwritten and does not call super' do
        @class.before(:hookable) { hi_mom! }
        @child = Class.new(@class) do
          def hookable; end;
        end

        inst = @child.new
        inst.should_not_receive(:hi_mom!)
        inst.hookable
      end

      it 'should not call hooks defined in the child class for a hookable method in a parent if the child overwrites the hookable method without calling super' do
        @child = Class.new(@class) do
          before(:hookable) { hi_mom! }
          def hookable; end;
        end

        inst = @child.new
        inst.should_not_receive(:hi_mom!)
        inst.hookable
      end

      it 'should not call hooks defined in child class even if hook method exists in parent' do
        @class.send(:define_method, :hello_world) { hello_world! }
        @child = Class.new(@class) do
          before(:hookable, :hello_world)
        end

        inst = @class.new
        inst.should_not_receive(:hello_world!)
        inst.hookable
      end

      it 'should pass the hookable method arguments to the hook method' do
        @class.class_eval %{def hook_this(word); end;}
        @class.class_eval %{def before_hook_this(word); word_up(word); end;}
        @class.register_instance_hooks(:hook_this)
        @class.before(:hook_this, :before_hook_this)

        inst = @class.new
        inst.should_receive(:word_up).with("omg")
        inst.hook_this("omg")
      end
      
      it 'should allow the use of before and after together'
      
      it "should allow advising methods ending in ? or !" do
        @class.class_eval do
          def hookable!; two! end;
          def hookable?; three! end;
          register_instance_hooks :hookable!, :hookable?
        end
        @class.before(:hookable!) { one! }
        @class.after(:hookable?) { four! }

        inst = @class.new
        inst.should_receive(:one!).once.ordered
        inst.should_receive(:two!).once.ordered
        inst.should_receive(:three!).once.ordered
        inst.should_receive(:four!).once.ordered

        inst.hookable!
        inst.hookable?
      end
      
      it "should allow advising methods ending in ?, ! or = when passing methods as advices"
    end
  end
  
  describe "using before hook" do
    
    describe "for class methods" do
      
      it "should install the advice block under the appropriate hook" do
        c = lambda { 1 }
        @class.should_receive(:install_hook).with(:before, :clakable, nil, :class, &c)
        @class.before_class_method(:clakable, &c)
      end
      
      it 'should install the advice method under the appropriate hook' do
        @class.class_eval %{def self.zomg; end;}
        @class.should_receive(:install_hook).with(:before, :clakable, :zomg, :class)
        @class.before_class_method(:clakable, :zomg)
      end
      
      it 'should run the advice before the advised method' do
        @class.class_eval %{def self.hook_me; second!; end;}
        @class.register_class_hooks(:hook_me)
        @class.before_class_method(:hook_me, :first!)

        @class.should_receive(:first!).ordered
        @class.should_receive(:second!).ordered
        @class.hook_me
      end
      
      it 'should execute all advices once in order' do
        @class.before_class_method(:clakable, :hook_1)
        @class.before_class_method(:clakable, :hook_2)
        @class.before_class_method(:clakable, :hook_3)

        @class.should_receive(:hook_1).once.ordered
        @class.should_receive(:hook_2).once.ordered
        @class.should_receive(:hook_3).once.ordered
        @class.clakable
      end
    end
    
    describe "for instance methods" do
      
      it "should install the advice block under the appropriate hook" do
        c = lambda { 1 }
        @class.should_receive(:install_hook).with(:before, :hookable, nil, :instance, &c)
        @class.before(:hookable, &c)
      end
      
      it 'should install the advice method under the appropriate hook' do
        @class.class_eval %{def zomg; end;}
        @class.should_receive(:install_hook).with(:before, :hookable, :zomg, :instance)
        @class.before(:hookable, :zomg)
      end
      
      it 'should run the advice before the advised method' do
        @class.class_eval %{
          def hook_me; second!; end;
        }
        @class.register_instance_hooks(:hook_me)
        @class.before(:hook_me, :first!)

        inst = @class.new
        inst.should_receive(:first!).ordered
        inst.should_receive(:second!).ordered
        inst.hook_me
      end
      
      it 'should execute all advices once in order' do
        @class.before(:hookable, :hook_1)
        @class.before(:hookable, :hook_2)
        @class.before(:hookable, :hook_3)

        inst = @class.new
        inst.should_receive(:hook_1).once.ordered
        inst.should_receive(:hook_2).once.ordered
        inst.should_receive(:hook_3).once.ordered
        inst.hookable
      end
    end
    
  end
  
  describe 'using after hook' do
    
    describe "for class methods" do
      
      it "should install the advice block under the appropriate hook" do
        c = lambda { 1 }
        @class.should_receive(:install_hook).with(:after, :clakable, nil, :class, &c)
        @class.after_class_method(:clakable, &c)
      end
      
      it 'should install the advice method under the appropriate hook' do
        @class.class_eval %{def self.zomg; end;}
        @class.should_receive(:install_hook).with(:after, :clakable, :zomg, :class)
        @class.after_class_method(:clakable, :zomg)
      end
      
      it "the advised method should still return its normal value"
      
      
      
    end
    
    describe "for instance methods" do
      
      it "should install the advice block under the appropriate hook" do
        c = lambda { 1 }
        @class.should_receive(:install_hook).with(:after, :hookable, nil, :instance, &c)
        @class.after(:hookable, &c)
      end
      
      it 'should install the advice method under the appropriate hook' do
        @class.class_eval %{def zomg; end;}
        @class.should_receive(:install_hook).with(:after, :hookable, :zomg, :instance)
        @class.after(:hookable, :zomg)
      end

      it "the advised method should still return its normal value"
      
    end
    
    
    
    
    it "should complain when only one argument is passed for class methods"
    it "should complain when target_method is not a symbol for class methods"
    it "should complain when method_sym is not a symbol"
    it "should complain when only one argument is passed"
    it "should complain when target_method is not a symbol"
    it "should complain when method_sym is not a symbol"
  end
  
  describe 'aborting' do
    it "should catch :halt from a before instance hook and abort the advised method"
    it "should catch :halt from an after instance hook and cease the advice"
    it "should catch :halt from a before class method hook and abort advised method"
    it "should catch :halt from an after class method hook and abort the rest of the advice"
  end
  
  describe "helper methods" do
    it 'should generate the correct argument signature' do
      @class.class_eval do
        def some_method(a, b, c)
          [a, b, c]
        end

        def yet_another(a, *heh)p
          [a, *heh]
        end
      end

      @class.args_for(@class.instance_method(:hookable)).should == ""
      @class.args_for(@class.instance_method(:some_method)).should == "_1, _2, _3"
      @class.args_for(@class.instance_method(:yet_another)).should == "_1, *args"
    end
  end
  
end