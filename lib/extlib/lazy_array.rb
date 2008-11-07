class LazyArray  # borrowed partially from StrokeDB
  instance_methods.each { |m| undef_method m unless %w[ __id__ __send__ send class dup object_id kind_of? respond_to? assert_kind_of should should_not instance_variable_set instance_variable_get extend ].include?(m.to_s) }

  include Enumerable

  # these methods should return self or nil
  RETURN_SELF = [ :concat, :collect!,
    :each, :each_index, :each_with_index, :insert, :map!,
    :reject!, :reverse!, :reverse_each, :sort! ]

  RETURN_SELF.each do |method|
    class_eval <<-EOS, __FILE__, __LINE__
      def #{method}(*args, &block)
        lazy_load
        results = @array.#{method}(*args, &block)
        results.kind_of?(Array) ? self : results
      end
    EOS
  end

  (Array.public_instance_methods(false).map { |m| m.to_sym } - RETURN_SELF - [ :taguri= ]).each do |method|
    class_eval <<-EOS, __FILE__, __LINE__
      def #{method}(*args, &block)
        lazy_load
        @array.#{method}(*args, &block)
      end
    EOS
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
    lazy_load
    @array.eql?(other.entries)
  end

  alias == eql?

  def load_with(&block)
    @load_with_proc = block
    self
  end

  def loaded?
    @loaded == true
  end

  def kind_of?(klass)
    super || @array.kind_of?(klass)
  end

  def respond_to?(method, include_private = false)
    super || @array.respond_to?(method, include_private)
  end

  def to_proc
    @load_with_proc
  end

  def include?(arg)
    if loaded?
      @array.include?(arg)
    else
      @tail.include?(arg) || @head.include?(arg) || super
    end
  end

  def delete_if(&block)
    if loaded?
      @array.delete_if(&block)
    else
      @reapers ||= []
      @reapers << block
      @head.delete_if(&block)
      @tail.delete_if(&block)
    end
    self
  end

  def first(*args)
    if lazy_possible?(@head, *args)
      @head.first(*args)
    elsif loaded?
      @array.first(*args)
    else
      super
    end
  end

  def last(*args)
    if lazy_possible?(@tail, *args)
      @tail.last(*args)
    elsif loaded?
      @array.last(*args)
    else
      super
    end
  end

  def shift
    if lazy_possible?(@head)
      @head.shift
    elsif loaded?
      @array.shift
    else
      super
    end
  end

  def unshift(*args)
    if loaded?
      @array.unshift(*args)
    else
      @head.unshift(*args)
    end
    self
  end

  def push(*args)
    if loaded?
      @array.push(*args)
    else
      @tail.push(*args)
    end
    self
  end

  def <<(arg)
    if loaded?
      @array << arg
    else
      @tail << arg
    end
    self
  end

  def pop
    if lazy_possible?(@tail)
      @tail.pop
    elsif loaded?
      @array.pop
    else
      super
    end
  end

  def freeze
    if loaded?
      @array.freeze
    else
      @head.freeze
      @tail.freeze
    end
    @frozen = true
    self
  end

  def frozen?
    @frozen == true
  end

  protected

  attr_reader :head, :tail

  def lazy_possible?(list, *args)
    raise ArgumentError("wrong number of arguments (#{args.size} for 1)") if args.size > 1
    !loaded? && ((args.empty? && list.any?) || (args.any? && args.first <= list.size))
  end

  private

  def initialize(*args, &block)
    @load_with_proc = proc { |v| v }
    @head           = []
    @tail           = []
    @array          = Array.new(*args, &block)
  end

  def initialize_copy(original)
    @array = original.entries
    load_with(&original)
    mark_loaded if original.loaded?
  end

  def lazy_load
    return if loaded?
    mark_loaded
    @load_with_proc[self]
    @array.unshift(*@head)
    @array.concat(@tail)
    @head = @tail = nil
    @reapers.each { |r| @array.delete_if(&r) } if @reapers
    @array.freeze if frozen?
  end

  def mark_loaded
    @loaded = true
  end

  # delegate any not-explicitly-handled methods to @array, if possible.
  # this is handy for handling methods mixed-into Array like group_by
  def method_missing(method, *args, &block)
    if @array.respond_to?(method)
      lazy_load
      @array.send(method, *args, &block)
    else
      super
    end
  end
end
