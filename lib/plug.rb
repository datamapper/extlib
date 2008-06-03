module Plug
  def self.included(target)
    target.extend(ClassMethods)
  end

  module ClassMethods
    def plug(target_method, plugin_method) 
      plugins[target_method] << plugin_method

      if plugins[target_method].length == 1
        alias_method target_method, plugin_method
      else
        class_eval <<-EOD
          def #{target_method}(*args)
            #{plugins[target_method].join("(*args)\n")}(*args)
          end
        EOD
      end
    end

    private

    def plugins
      @plugins ||= Hash.new { |h, k| h[k] = [] }
    end
  end
end
