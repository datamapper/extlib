class Module
  def find_const(nested_name)
    if nested_name =~ /^\:\:/
      Object::__nested_constants__(nested_name)
    else
      begin
        self.__nested_constants__(nested_name)
      rescue NameError
        Object::__nested_constants__(nested_name)
      end
    end
  end

protected
  # Doesn't do any caching since constants can change with remove_const
  def __nested_constants__(k)
    klass = self
    modules = [Object]
    keys = k.split('::')

    if keys.first.blank? # We got "::Foo::Bar", so we'll get rid of the opening '::', and only search Object
      keys.shift
    else
      klass.name.split('::').inject(modules) do |ary, elem|
        ary << ary.last.const_get(elem)
        ary
      end
      modules.reverse!
    end

    modules.each do |m|
      keys.inject(m) do |group, elem|
        break unless group.const_defined?(elem)
        klass = group.const_get(elem)
      end
      break unless klass == self
    end

    raise NameError if klass == Object

    klass
  end

end # class Module
