class LazyArray  # borrowed partially from StrokeDB
  instance_methods.each { |m| undef_method m unless %w[ __id__ __send__ send class dup object_id kind_of? respond_to? equal? assert_kind_of should should_not instance_variable_set instance_variable_get extend ].include?(m.to_s) }

  include Enumerable

  # these methods should return self or nil
  RETURN_SELF = [ :collect!, :each, :each_index, :each_with_index, :map!, :reject!, :reverse_each, :sort! ]

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

  def first(*args)
    if lazy_possible?(@head, *args)
      @head.first(*args)
    else
      super
    end
  end

  def last(*args)
    if lazy_possible?(@tail, *args)
      @tail.last(*args)
    else
      super
    end
  end

  def at(index)
    if index >= 0 && lazy_possible?(@head, index + 1)
      @head.at(index)
    elsif index < 0 && lazy_possible?(@tail, index.abs)
      @tail.at(index)
    else
      super
    end
  end

  def fetch(*args, &block)
    index = args.first

    if index >= 0 && lazy_possible?(@head, index + 1)
      @head.fetch(*args, &block)
    elsif index < 0 && lazy_possible?(@tail, index.abs)
      @tail.fetch(*args, &block)
    else
      super
    end
  end

  def values_at(*args)
    accumulator = []

    lazy_possible = args.all? do |arg|
      index, length = extract_slice_arguments(arg)

      if index >= 0 && lazy_possible?(@head, index + (length || 1))
        accumulator.concat(head.values_at(*arg))
      elsif index < 0 && lazy_possible?(@tail, index.abs)
        accumulator.concat(tail.values_at(*arg))
      end
    end

    if lazy_possible
      accumulator
    else
      super
    end
  end

  def index(entry)
    (lazy_possible?(@head) && @head.index(entry)) || super
  end

  def include?(entry)
    (lazy_possible?(@tail) && @tail.include?(entry)) ||
    (lazy_possible?(@head) && @head.include?(entry)) ||
    super
  end

  def empty?
    !any?
  end

  def any?
    (lazy_possible?(@tail) && @tail.any?) ||
    (lazy_possible?(@head) && @head.any?) ||
    super
  end

  def [](*args)
    index, length = extract_slice_arguments(*args)

    if length.nil?
      return at(index)
    end

    length ||= 1

    if index >= 0 && lazy_possible?(@head, index + length)
      @head.slice(*args)
    elsif index < 0 && lazy_possible?(@tail, index.abs - 1 + length)
      @tail.slice(*args)
    else
      super
    end
  end

  alias slice []

  def slice!(*args)
    index, length = extract_slice_arguments(*args)

    length ||= 1

    if index >= 0 && lazy_possible?(@head, index + length)
      @head.slice!(*args)
    elsif index < 0 && lazy_possible?(@tail, index.abs - 1 + length)
      @tail.slice!(*args)
    else
      super
    end
  end

  def []=(*args)
    index, length = extract_slice_arguments(*args[0..-2])

    length ||= 1

    if index >= 0 &&  lazy_possible?(@head, index + length)
      @head.[]=(*args)
    elsif index < 0 && lazy_possible?(@tail, index.abs - 1 + length)
      @tail.[]=(*args)
    else
      super
    end
  end

  alias splice []=

  def reverse
    dup.reverse!
  end

  def reverse!
    # reverse without kicking if possible
    if loaded?
      @array = @array.reverse
    else
      @head, @tail = @tail.reverse, @head.reverse

      proc = @load_with_proc

      @load_with_proc = lambda do |v|
        proc.call(v)
        v.instance_variable_get(:@array).reverse!
      end
    end

    self
  end

  def <<(entry)
    if loaded?
      super
    else
      @tail << entry
    end
    self
  end

  alias add <<

  def concat(other)
    if loaded?
      super
    else
      @tail.concat(other)
    end
    self
  end

  def push(*entries)
    if loaded?
      @array.push(*entries)
    else
      @tail.push(*entries)
    end
    self
  end

  def unshift(*entries)
    if loaded?
      @array.unshift(*entries)
    else
      @head.unshift(*entries)
    end
    self
  end

  def insert(index, *entries)
    if loaded?
      @array.insert(index, *entries)
    elsif index >= 0
      if lazy_possible?(@head, index)
        @head.insert(index, *entries)
      else
        super
      end
    else
      if lazy_possible?(@tail, index.abs - 1)
        @tail.insert(index, *entries)
      else
        super
      end
    end
    self
  end

  def pop
    if loaded?
      @array.pop
    elsif lazy_possible?(@tail)
      @tail.pop
    else
      super
    end
  end

  def shift
    if loaded?
      @array.shift
    elsif lazy_possible?(@head)
      @head.shift
    else
      super
    end
  end

  def delete_at(index)
    if loaded?
      @array.delete_at(index)
    elsif index >= 0
      if lazy_possible?(@head, index + 1)
        @head.delete_at(index)
      else
        super
      end
    else
      if lazy_possible?(@tail, index.abs)
        @tail.delete_at(index)
      else
        super
      end
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

  def eql?(other)
    lazy_load
    @array.eql?(other.entries)
  end

  alias == eql?

  protected

  attr_reader :head, :tail

  def lazy_possible?(list, need_length = 1)
    !loaded? && need_length <= list.size
  end

  private

  def initialize(*args, &block)
    @load_with_proc = proc { |v| v }
    @head           = []
    @tail           = []
    @array          = Array.new(*args, &block)
  end

  def initialize_copy(original)
    if original.loaded?
      mark_loaded
      @array = @array.dup
      @head = @tail = nil
    else
      @head  = @head.dup
      @tail  = @tail.dup
      @array = @array.dup
    end
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

  ##
  # Extract arguments for #slice an #slice! and return index and length
  #
  # @param [Integer, Array(Integer), Range] *args the index,
  #   index and length, or range indicating first and last position
  #
  # @return [Integer] the index
  # @return [Integer,NilClass] the length, if any
  #
  # @api private
  def extract_slice_arguments(*args)
    first_arg, second_arg = args

    if args.size == 2 && first_arg.kind_of?(Integer) && second_arg.kind_of?(Integer)
      return first_arg, second_arg
    elsif args.size == 1
      if first_arg.kind_of?(Integer)
        return first_arg
      elsif first_arg.kind_of?(Range)
        index = first_arg.first
        length  = first_arg.last - index
        length += 1 unless first_arg.exclude_end?
        return index, length
      end
    end

    raise ArgumentError, "arguments may be 1 or 2 Integers, or 1 Range object, was: #{args.inspect}", caller(1)
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
