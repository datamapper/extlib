class LazyArray  # borrowed partially from StrokeDB

  # these methods should return self or nil
  RETURN_SELF = [ :<<, :clear, :concat, :collect!, :each, :each_index,
    :each_with_index, :insert, :map!, :push, :replace, :reject!,
    :reverse!, :reverse_each, :sort!, :unshift ]

  # these methods should return their results as-is to the caller
  RETURN_PLAIN = [ :&, :|, :+, :-, :[], :[]=, :all?, :any?, :at,
    :blank?, :collect, :delete, :delete_at, :delete_if, :detect,
    :empty?, :entries, :fetch, :find, :find_all, :first, :grep,
    :include?, :index, :inject, :inspect, :last, :length, :map,
    :member?, :pop, :reject, :reverse, :rindex, :select, :shift, :size,
    :slice, :slice!, :sort, :sort_by, :to_a, :to_ary, :to_s, :to_set,
    :values_at, :zip ]

  RETURN_SELF.each do |method|
    class_eval <<-EOS, __FILE__, __LINE__
      def #{method}(*args, &block)
        lazy_load!
        results = @array.#{method}(*args, &block)
        results.kind_of?(Array) ? self : results
      end
    EOS
  end

  RETURN_PLAIN.each do |method|
    class_eval <<-EOS, __FILE__, __LINE__
      def #{method}(*args, &block)
        lazy_load!
        @array.#{method}(*args, &block)
      end
    EOS
  end

  def partition(&block)
    lazy_load!
    true_results, false_results = @array.partition(&block)
    [ true_results, false_results ]
  end

  def replace(other)
    mark_loaded
    @array.replace(other.entries)
    self
  end

  def clear
    mark_loaded
    @array.clear
    self
  end

  def eql?(other)
    @array.eql?(other.entries)
  end

  alias == eql?

  def load_with(&block)
    @load_with_proc = block
    self
  end

  def loaded?
    # proc will be nil if the array was loaded
    @load_with_proc.nil?
  end

  def respond_to?(method)
    super || @array.respond_to?(method)
  end

  private

  def initialize(*args, &block)
    @load_with_proc = proc { |v| v }
    @array          = Array.new(*args, &block)
  end

  def initialize_copy(original)
    @array = original.entries
    mark_loaded if @array.any?
  end

  def lazy_load!
    if proc = @load_with_proc
      mark_loaded
      proc[self]
    end
  end

  def mark_loaded
    @load_with_proc = nil
  end

  # delegate any not-explicitly-handled methods to @array, if possible.
  # this is handy for handling methods mixed-into Array like group_by
  def method_missing(method, *args, &block)
    if @array.respond_to?(method)
      lazy_load!
      @array.send(method, *args, &block)
    else
      super
    end
  end
end
