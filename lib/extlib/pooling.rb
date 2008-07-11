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
  # method that returns instances acquired from pool.
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

    def self.scavenger
      @scavenger || begin
        @scavenger = Thread.new do
          loop do
            lock.synchronize do
              pools.each do |pool|
                # This is a useful check, but non-essential, and right now it breaks lots of stuff.
                # if pool.expired?
                pool.lock.synchronize do
                  if pool.reserved_count == 0
                    pool.dispose
                  end
                end
                # end
              end
            end
            sleep(scavenger_interval)
          end # loop
        end

        @scavenger.priority = -10
        @scavenger
      end
    end

    def self.pools
      @pools ||= Set.new
    end

    def self.append_pool(pool)
      lock.synchronize do
        pools << pool
      end
      Extlib::Pooling::scavenger
    end

    def self.lock
      @lock ||= Mutex.new
    end

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

        @__pools = Hash.new { |h,k| __pool_lock.synchronize { h[k] = Pool.new(target.pool_size, target, k) } }
        @__pool_lock = Mutex.new

        def self.__pool_lock
          @__pool_lock
        end

        def self.new(*args)
          @__pools[args].new
        end

        def self.__pools
          @__pools
        end

        def self.pool_size
          8
        end
      end
    end

    def release
      @__pool.release(self) unless @__pool.nil?
    end

    class Pool
      def initialize(max_size, resource, args)
        raise ArgumentError.new("+max_size+ should be a Fixnum but was #{max_size.inspect}") unless Fixnum === max_size
        raise ArgumentError.new("+resource+ should be a Class but was #{resource.inspect}") unless Class === resource

        @max_size = max_size
        @resource = resource
        @args = args

        @available = []
        @reserved_count = 0
      end

      def lock
        @resource.__pool_lock
      end

      def scavenge_interval
        @resource.scavenge_interval
      end

      def new
        instance = nil

        lock.synchronize do
          instance = acquire
        end

        Extlib::Pooling::append_pool(self)

        if instance.nil?
          # Account for the current thread, and the pool scavenger.
          if ThreadGroup::Default.list.size == 2 && @reserved_count >= @max_size
            raise ThreadStopError.new(size)
          else
            sleep(0.05)
            new
          end
        else
          instance
        end
      end

      def release(instance)
        lock.synchronize do
          instance.instance_variable_set(:@__pool, nil)
          @reserved_count -= 1
          @available.push(instance)
        end
        nil
      end

      def delete(instance)
        lock.synchronize do
          instance.instance_variable_set(:@__pool, nil)
          @reserved_count -= 1
        end
        nil
      end

      def size
        @available.size + @reserved_count
      end
      alias length size

      def inspect
        "#<Extlib::Pooling::Pool<#{@resource.name}> available=#{@available.size} reserved_count=#{@reserved_count}>"
      end

      def flush!
        @available.pop.dispose until @available.empty?
      end

      def dispose
        flush!
        @resource.__pools.delete(@args)
        !Extlib::Pooling::pools.delete?(self).nil?
      end

      # Disabled temporarily.
      #
      # def expired?
      #   lock.synchronize do
      #     @available.each do |instance|
      #       if instance.instance_variable_get(:@__allocated_in_pool) + scavenge_interval < Time.now
      #         instance.dispose
      #         @available.delete(instance)
      #       end
      #     end
      #
      #     size == 0
      #   end
      # end

      def reserved_count
        @reserved_count
      end

      private

      def acquire
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
          @reserved_count += 1
          instance.instance_variable_set(:@__pool, self)
          instance.instance_variable_set(:@__allocated_in_pool, Time.now)
          instance
        end
      end
    end

    def self.scavenger_interval
      60
    end
  end # module Pooling
end # module Extlib
