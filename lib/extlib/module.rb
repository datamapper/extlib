class Module
  def find_const(nested_name)
    if nested_name =~ /^\:\:/
      Object::__nested_constants__[nested_name]
    else
      begin
        self.__nested_constants__[nested_name]
      rescue NameError
        Object::__nested_constants__[nested_name]
      end
    end
  end

  protected
  def __nested_constants__
    @__nested_constants__ ||= Hash.new do |h,k|
      klass = self
      if klass == Object
        k.split('::').each do |c|
          klass = klass.const_get(c) unless c.empty?
        end
        h[k] = klass
      else
        modules = [Object]
        klass.name.split('::').inject(modules) do |ary, elem|
          ary << ary.last.const_get(elem)
          ary
        end
        modules.reverse.each do |m|
          break klass = m.const_get(k) if m.const_defined?(k)
        end
        h[k] = klass
      end
    end
  end

end # class Module