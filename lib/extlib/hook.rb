#
# TODO: Write more documentation!
#
# Currently, before you can set a before or after hook on a method, you must
# register that method as hookable; otherwise, their invocation of the hook
# stack is not created.
#
# This can be done by calling #register_class_hooks to register one or more
# class methods as hookable or #register_instance_hooks to register one or
# more instance methods as hookable.
#
# Eventually, I'll probably have #before, #after, #before_class_method, and
# #after_class_method implicitly call #register_instance_hooks and
# #register_class_hooks respectivly. That way, if the exact hook insertion
# location does not need to be specified, hooks can be added on the fly.
#
module Hook
  
  def self.included(base)
    base.extend(ClassMethods)
    base.const_set("CLASS_HOOKS", {})
    base.const_set("INSTANCE_HOOKS", {})
  end
  
  module ClassMethods
    include Extlib::Assertions
    # Inject code that executes before the target class method.
    #
    # @param target_method<Symbol>  the name of the class method to inject before
    # @param method_sym<Symbol>     the name of the method to run before the
    #   target_method
    # @param block<Block>           the code to run before the target_method
    #
    # @note
    #   Either method_sym or block is required.
    # -
    # @api public
    def before_class_method(target_method, method_sym = nil, &block)
      install_hook :before, target_method, method_sym, :class, &block
    end

    #
    # Inject code that executes after the target class method.
    #
    # @param target_method<Symbol>  the name of the class method to inject after
    # @param method_sym<Symbol>     the name of the method to run after the target_method
    # @param block<Block>           the code to run after the target_method
    #
    # @note
    #   Either method_sym or block is required.
    # -
    # @api public
    def after_class_method(target_method, method_sym = nil, &block)
      install_hook :after, target_method, method_sym, :class, &block
    end
    
    #
    # Inject code that executes before the target instance method.
    #
    # @param target_method<Symbol>  the name of the instance method to inject before
    # @param method_sym<Symbol>     the name of the method to run before the
    #   target_method
    # @param block<Block>           the code to run before the target_method
    #
    # @note
    #   Either method_sym or block is required.
    # -
    # @api public
    def before(target_method, method_sym = nil, &block)
      install_hook :before, target_method, method_sym, :instance, &block
    end
    
    #
    # Inject code that executes after the target instance method.
    #
    # @param target_method<Symbol>  the name of the instance method to inject after
    # @param method_sym<Symbol>     the name of the method to run after the
    #   target_method
    # @param block<Block>           the code to run after the target_method
    #
    # @note
    #   Either method_sym or block is required.
    # -
    # @api public
    def after(target_method, method_sym = nil, &block)
      install_hook :after, target_method, method_sym, :instance, &block
    end
    
    # Register a class method as hookable. Registering a method means that
    # before hooks will be run immedietly before the method is invoked and
    # after hooks will be called immedietly after the method is invoked.
    #
    # @param hookable_method<Symbol> The name of the class method that should
    #   be hookable
    # -
    # @api public
    def register_class_hooks(*hooks)
      hooks.each { |hook| register_hook(hook, :class) }
    end
    
    # Register aninstance method as hookable. Registering a method means that
    # before hooks will be run immedietly before the method is invoked and
    # after hooks will be called immedietly after the method is invoked.
    #
    # @param hookable_method<Symbol> The name of the instance method that should
    #   be hookable
    # -
    # @api public
    def register_instance_hooks(*hooks)
      hooks.each { |hook| register_hook(hook, :instance) }
    end
    
    # Not yet implemented
    def reset_hook!(target_method, scope)
      raise NotImplementedError
    end
    
    # --- Alright kids... the rest is internal stuff ---
    
    def hooks_with_scope(scope)
      case scope
        when :class    then class_hooks
        when :instance then instance_hooks
        else raise ArgumentError, 'You need to pass :class or :instance as scope'
      end
    end
    
    def class_hooks
      self.const_get("CLASS_HOOKS")
    end
    
    def instance_hooks
      self.const_get("INSTANCE_HOOKS")
    end
    
    def register_hook(target_method, scope)
      if scope == :instance && !method_defined?(target_method)
        raise ArgumentError, "#{target_method} instance method does not exist"
      elsif scope == :class && !respond_to?(target_method)
        raise ArgumentError, "#{target_method} class method does not exist"
      end
      
      hooks = hooks_with_scope(scope)
      
      if hooks[target_method].nil?  
        hooks[target_method] = {
          :before => [], :after => [], :in => self
        }
        
        define_hook_stack_execution_methods(target_method, scope)
        define_advised_method(target_method, scope)
      end
    end
    
    def define_hook_stack_execution_methods(target_method, scope)
      hooks = hooks_with_scope(scope)
      
      if hooks[target_method].nil?
        raise ArgumentError, "#{target_method} has not be registered as a hookable method"
      end
      
      before_hook_stack = "execute_before_" + "#{target_method}".sub(/([?!=]?$)/, '_hook_stack\1')
      after_hook_stack  = "execute_after_" + "#{target_method}".sub(/([?!=]?$)/, '_hook_stack\1')
      
      before_hooks = hooks[target_method][:before]
      before_hooks = before_hooks.map{ |info| inline_call(info, scope) }.join("\n")
      
      after_hooks  = hooks[target_method][:after]
      after_hooks  = after_hooks.map{ |info| inline_call(info, scope) }.join("\n")
      
      source = %{
        def #{before_hook_stack}(*args)
          #{before_hooks}
        end
        
        def #{after_hook_stack}(*args)
          #{after_hooks}
        end
      }
      
      source = %{class << self\n#{source}\nend} if scope == :class
      
      hooks[target_method][:in].class_eval(source)
    end
    
    # The respond_to is kind of ghetto. Actually it won't work
    def inline_call(method_info, scope)
      if scope == :instance
        %(#{method_info[:name]}(*args) if self.class <= ObjectSpace._id2ref(#{method_info[:from].object_id}))
      else
        %(#{method_info[:name]}(*args) if self <= ObjectSpace._id2ref(#{method_info[:from].object_id}))
      end
    end
    
    def define_advised_method(target_method, scope)
      args = args_for(method_with_scope(target_method, scope))
      
      renamed_target    = "#{target_method}".sub(/([?!=]?$)/, '_before_advised\1')
      before_hook_stack = "execute_before_" + "#{target_method}".sub(/([?!=]?$)/, '_hook_stack\1')
      after_hook_stack  = "execute_after_" + "#{target_method}".sub(/([?!=]?$)/, '_hook_stack\1')
      
      source = <<-EOD
        alias_method :#{renamed_target}, :#{target_method}
        
        def #{target_method}(#{args})
          retval = nil
          catch(:halt) do
            #{before_hook_stack}(#{args})
            retval = #{renamed_target}(#{args})
          end

          catch(:halt) do
            #{after_hook_stack}(#{args})
          end
          retval
        end
      EOD
      
      source = %{class << self\n#{source}\nend} if scope == :class
      
      class_eval(source)
    end
    
    # --- Add a hook ---
    
    def install_hook(type, target_method, method_sym, scope, &block)
      assert_kind_of 'target_method', target_method, Symbol
      assert_kind_of 'method_sym',    method_sym,    Symbol unless method_sym.nil?
      assert_kind_of 'scope',         scope,         Symbol

      if !block_given? and method_sym.nil?
        raise ArgumentError, "You need to pass 2 arguments to \"#{type}\"."
      end
      
      unless [ :class, :instance ].include?(scope)
        raise ArgumentError, 'You need to pass :class or :instance as scope'
      end
      
      hooks = hooks_with_scope(scope)
      
      if hooks[target_method].nil?
        raise ArgumentError, "#{target_method} has not be registered as a hookable method"
      end
      
      if block
        method_sym = "__hooks_#{type}_#{quote_method(target_method)}_#{hooks[target_method][type].length}".to_sym
        if scope == :class
          (class << self; self; end;).instance_eval do
            define_method(method_sym, &block)
          end
        else
          define_method(method_sym, &block)
        end
      end
      
      # Adds method to the stack an redefines the hook invocation method
      hooks[target_method][type] << { :name => method_sym, :from => self }
      define_hook_stack_execution_methods(target_method, scope)
    end
    
    # --- Helpers ---
  
    def args_for(method)
      if method.arity == 0
        ""
      elsif method.arity > 0
        "_" << (1 .. method.arity).to_a.join(", _")
      elsif (method.arity + 1) < 0
        "_" << (1 .. (method.arity).abs - 1).to_a.join(", _") << ", *args"
      else
        "*args"
      end
    end
    
    def method_with_scope(name, scope)
      case scope
        when :class    then method(name)
        when :instance then instance_method(name)
        else raise ArgumentError, 'You need to pass :class or :instance as scope'
      end
    end
    
    def quote_method(name)
      name.to_s.gsub(/\?$/, '_q_').gsub(/!$/, '_b_').gsub(/=$/, '_eq_')
    end
  end
  
end