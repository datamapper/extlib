class Object
  unless instance_methods.include?('instance_variable_defined?')
    def instance_variable_defined?(method)
      instance_variables.include?(method.to_s)
    end
  end
end # class Object
