require 'set'
require 'thread'

module Extlib
  # ==== Notes
  # Provides pooling support to class it got included in.
  #
  # Pooling of objects is a faster way of aquiring instances
  # of objects compared to regular allocation and initialization
  # because instances are keeped in memory reused.
  #
  # Classes that include Pooling module have re-defined new
  # method that returns instances aquired from pool.
  #
  # Term resource is used for any type of poolable objects
  # and should NOT be thought as DataMapper Resource or
  # ActiveResource resource and such.
  #
  # In Data Objects connections are pooled so that it is
  # unnecessary to allocate and initialize connection object
  # each time connection is needed, like per request in a
  # web application.
  #
  # Pool obviously has to be thread safe because state of
  # object is reset when it is released.
  module Pooling
    
    class CrossPoolError < StandardError
    end
    
    class OrphanedObjectError < StandardError
    end
    
    class ThreadStopError < StandardError
    end
    
    def self.included(target)
      target.class_eval do
        class << self
          alias __new new
        end
        
        @__pools = Hash.new { |h,k| h[k] = Pool.new(target.pool_size, target, k) }
        
        def self.new(*args)
          @__pools[args].new
        end
          
        def self.__pools
          @__pools
        end
          
        def self.pool_size
          1
        end
      end
    end

    def release
      @__pool.release(self)
    end
    
    class Pool
      def initialize(max_size, resource, args)
        @max_size = max_size
        @resource = resource
        @args = args
        
        @lock = Mutex.new
        @available = []
        @reserved = Set.new
      end
      
      def new
        instance = nil
        
        @lock.synchronize do
          instance = aquire
        end
        
        if instance.nil?
          if ThreadGroup::Default.list.size == 1 && @reserved.size >= @max_size
            raise ThreadStopError.new(size)
          else
            Thread.pass
            new
          end
        else
          instance
        end
      end
      
      def release(instance)
        @lock.synchronize do
          raise OrphanedObjectError.new(instance) unless @reserved.delete?(instance)
          instance.instance_variable_set(:@__pool, nil)
          @available.push(instance)
        end
        nil
      end
      
      def size
        @available.size + @reserved.size
      end
      alias length size
      
      def inspect
        "#<Extlib::Pooling::Pool available=#{@available.size} reserved=#{@reserved.size}>"
      end
      
      private
      
      def aquire
        instance = if !@available.empty?
          @available.pop
        elsif size < @max_size
          @resource.__new(*@args)
        else
          nil
        end
        
        if instance.nil?
          instance
        else
          raise CrossPoolError.new(instance) if instance.instance_variable_get(:@__pool)
          @reserved << instance
          instance.instance_variable_set(:@__pool, self)
          instance
        end
      end
    end
    
  #   module ClassMethods
  #     # ==== Notes
  #     # Initializes the pool and returns it.
  #     #
  #     # ==== Parameters
  #     # size_limit<Fixnum>:: maximum size of the pool.
  #     #
  #     # ==== Returns
  #     # <ResourcePool>:: initialized pool
  #     def initialize_pool(size_limit, options = {})
  #       @__pool.flush! if @__pool
  # 
  #       @__pool = ResourcePool.new(size_limit, self, options)
  #     end
  # 
  #     # ==== Notes
  #     # Instances of poolable resource are aquired from
  #     # pool. This quires a new instance from pool and
  #     # returns it.
  #     #
  #     # ==== Returns
  #     # Resource instance aquired from the pool.
  #     #
  #     # ==== Raises
  #     # ArgumentError:: when pool is exhausted and no instance
  #     #                 can be aquired.
  #     def new(*args)
  #       pool.aquire(*args)
  #     end
  # 
  #     # ==== Notes
  #     # Returns pool for this resource class.
  #     # Initialization is done when necessary.
  #     # Default size limit of the pool is 10.
  #     #
  #     # ==== Returns
  #     # <Object::Pooling::ResourcePool>:: pool for this resource class.
  #     def pool
  #       @__pool ||= ResourcePool.new(10, self)
  #     end
  #   end
  # 
  #   # ==== Notes
  #   # Pool
  #   #
  #   class ResourcePool
  #     attr_reader :size_limit, :class_of_resources, :expiration_period
  # 
  #     # ==== Notes
  #     # Initializes resource pool.
  #     #
  #     # ==== Parameters
  #     # size_limit<Fixnum>:: maximum number of resources in the pool.
  #     # class_of_resources<Class>:: class of resource.
  #     #
  #     # ==== Raises
  #     # ArgumentError:: when class of resource does not implement
  #     #                 dispose instance method or is not a Class.
  #     def initialize(size_limit, class_of_resources, options)
  #       raise ArgumentError.new("Expected class of resources to be instance of Class, got: #{class_of_resources.class}") unless class_of_resources.is_a?(Class)
  #       raise ArgumentError.new("Class #{class_of_resources} must implement dispose instance method to be poolable.") unless class_of_resources.instance_methods.include?("dispose")
  # 
  #       @size_limit         = size_limit
  #       @class_of_resources = class_of_resources
  # 
  #       @reserved  = Set.new
  #       @available = Hash.new { |h,k| h[k] = [] }
  #       @lock      = Mutex.new
  # 
  #       initialization_args  = options.delete(:initialization_args) || []
  # 
  #       @expiration_period   = options.delete(:expiration_period) || 60
  #       @initialization_args = [*initialization_args]
  # 
  #       @pool_expiration_thread = Thread.new do
  #         while true
  #           dispose_outdated
  # 
  #           sleep (@expiration_period + 1)
  #         end
  #       end
  #     end
  # 
  #     # ==== Notes
  #     # Current size of pool: number of already reserved
  #     # resources.
  #     def size
  #       @reserved.size
  #     end
  # 
  #     # ==== Notes
  #     # Indicates if pool has resources to aquire.
  #     #
  #     # ==== Returns
  #     # <Boolean>:: true if pool has resources can be aquired,
  #     #             false otherwise.
  #     def available?
  #       @reserved.size < size_limit
  #     end
  # 
  #     # ==== Notes
  #     # Aquires last used available resource and returns it.
  #     # If no resources available, current implementation
  #     # throws an exception.
  #     def aquire(*args)
  #       @lock.synchronize do
  #         resource = if @available[args].size > 0
  #           @available[args].pop
  #         else
  #           @class_of_resources.__new(*@initialization_args)
  #         end
  #         
  #         resource.instance_variable_set("@__pool_aquire_timestamp", Time.now)
  #         @reserved << resource
  #         resource
  #       end
  #     end
  # 
  #     # ==== Notes
  #     # Releases previously aquired instance.
  #     #
  #     # ==== Parameters
  #     # instance <Anything>:: previosly aquired instance.
  #     #
  #     # ==== Raises
  #     # RuntimeError:: when given not pooled instance.
  #     def release(instance)
  #       @lock.synchronize do
  #         if @reserved.include?(instance)
  #           @reserved.delete(instance)
  #           # TODO: objects should only be disposed when the pool is being
  #           # flushed, not simply when the object is released
  #           @available << instance
  #         else
  #           raise RuntimeError
  #         end
  #       end
  #     end
  # 
  #     # ==== Notes
  #     # Releases all objects in the pool.
  #     #
  #     # ==== Returns
  #     # nil
  #     def flush!
  #       @reserved.each do |instance|
  #         self.release(instance)
  #         instance.dispose
  #       end
  #       nil
  #     end
  # 
  #     # ==== Notes
  #     # Check if instance has been aquired from the pool.
  #     #
  #     # ==== Returns
  #     # <Boolean>:: true if given resource instance has been aquired from pool,
  #     #             false otherwise.
  #     def aquired?(instance)
  #       @reserved.include?(instance)
  #     end
  # 
  #     # ==== Notes
  #     # Disposes of instances that haven't been in use and
  #     # hit the expiration period.
  #     #
  #     # ==== Returns
  #     # nil
  #     def dispose_outdated
  #       @reserved.each do |instance|
  #         release(instance) if time_to_release?(instance)
  #       end
  # 
  #       nil
  #     end
  # 
  #     # ==== Notes
  #     # Checks if pooled resource instance is outdated and
  #     # should be released.
  #     #
  #     # ==== Returns
  #     # <Boolean>:: true if instance should be released, false otherwise.
  #     def time_to_release?(instance)
  #       (Time.now - instance.instance_variable_get("@__pool_aquire_timestamp")) > @expiration_period
  #     end
  # 
  #   end # ResourcePool
  end # module Pooling
end # module Extlib
