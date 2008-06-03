require File.join(File.dirname(__FILE__), '..', 'lib', 'plug')

describe Plug do
  describe "should allow inclusion" do
    it "in a class" do
      klass = Class.new do
        include Plug
      end

      klass.should respond_to(:plug)
    end

    it "in a module" do
      mod = Module.new do
        include Plug
      end

      mod.should respond_to(:plug)
    end
  end

  describe "should plug" do
    it "into a class" do
      plugin = Module.new do
        def self.included(target)
          target.plug :target_method, :plugin_method
        end

        def plugin_method
        end
      end

      target = Class.new do
        include Plug

        def target_method
        end

        include plugin
      end
    end

    it "into a module" do
      plugin = Module.new do
        def self.included(target)
          target.plug :target_method, :plugin_method
        end

        def plugin_method
        end
      end

      target = Module.new do
        include Plug

        def target_method
        end

        include plugin
      end

      target.instance_methods.should include("plugin_method")
    end
  end

  describe "should execute a method" do
    it "with no args" do
      mk = mock("tester")
      mk.should_receive(:call).with(no_args)
      mod = Module.new do
        def self.included(target)
          target.plug :target, :plugin
        end

        def plugin
          @mk.call
        end
      end
      klass = Class.new do
        include Plug

        def main(mock)
          @mk = mock
          target
        end

        def target
        end

        include mod
      end

      klass.new.main(mk)
    end

    it "with args" do
      mk = mock("tester")
      mk.should_receive(:call).with(1)
      mod = Module.new do
        def self.included(target)
          target.plug :target, :plugin
        end

        define_method :plugin do |one|
          mk.call one
        end
      end
      klass = Class.new do
        include Plug

        def main
          target(1)
        end

        def target(one)
        end

        include mod
      end

      klass.new.main
    end

    describe "more than one method" do
      it "with no args" do
        mk = mock("tester")
        mk.should_receive(:one).once
        mk.should_receive(:two).once
        mod = Module.new do
          def self.included(target)
            target.plug :target, :plugin
            target.plug :target, :plugin2
          end

          def plugin
            @mk.one
          end

          def plugin2
            @mk.two
          end
        end
        klass = Class.new do
          include Plug

          def main(mock)
            @mk = mock
            target
          end

          def target
          end

          include mod
        end

        klass.new.main(mk)
      end

      it "with args" do
        mk = mock("tester")
        mk.should_receive(:one).once.with(1)
        mk.should_receive(:two).once.with(1)
        mod = Module.new do
          def self.included(target)
            target.plug :target, :plugin
            target.plug :target, :plugin2
          end

          def plugin(arg)
            @mk.one(arg)
          end

          def plugin2(arg)
            @mk.two(arg)
          end
        end
        klass = Class.new do
          include Plug

          def main(mock)
            @mk = mock
            target(1)
          end

          def target(arg)
          end

          include mod
        end

        klass.new.main(mk)
      end
    end
  end
end
