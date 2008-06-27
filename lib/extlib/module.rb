class Module
  def find_const(nested_name)
    self.__nested_constants__[nested_name]
  rescue NameError
    Object::__nested_constants__[nested_name]
  end

  protected
  def __nested_constants__
    @__nested_constants__ ||= Hash.new do |h,k|
      klass = self
      k.split('::').each do |c|
        klass = klass.const_get(c) unless c.empty?
      end
      h[k] = klass
    end
  end

end # class Module
