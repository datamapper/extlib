#!/usr/bin/env ruby
require "rubygems"
require "rbench"

require "pathname"

class String
  ##
  # @return <String> The string converted to camel case.
  #
  # @example
  #   "foo_bar".camel_case #=> "FooBar"
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end
  
  # By default, camelize converts strings to UpperCamelCase.
  #
  # camelize will also convert '/' to '::' which is useful for converting paths to namespaces
  #
  # @example
  #   "active_record".camelize #=> "ActiveRecord"
  #   "active_record/errors".camelize #=> "ActiveRecord::Errors"
  #
  def camelize
    self.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  end  
end # class String



# It's not really fair to compare the two but
# Extlib has no direct equivalent to String#camel_case.
RBench.run(10_000) do
  report "String#camelize" do
    "underscore_string".camelize
    "a_bit_longer_underscore_string".camelize
  end

  report "String#camel_case" do
    "underscore_string".camel_case
    "a_bit_longer_underscore_string".camel_case
  end
end