#!/usr/bin/env ruby
require "rubygems"
require "rbench"

class String 
  ##
  # @return <String> The string converted to snake case.
  #
  # @example
  #   "FooBar".snake_case #=> "foo_bar"
  # @example
  #   "HeadlineCNNNews".snake_case #=> "headline_cnn_news"
  # @example
  #   "CNN".snake_case #=> "cnn"
  def snake_case
    return self.downcase if self =~ /^[A-Z]+$/
    self.gsub(/([A-Z]+)(?=[A-Z][a-z]?)|\B[A-Z]/, '_\&') =~ /_*(.*)/
      return $+.downcase
  end
  
  ##
  # @return <String>
  #   The path that is associated with the constantized string, assuming a
  #   conventional structure.
  #
  # @example
  #   "FooBar::Baz".to_const_path # => "foo_bar/baz"
  def to_const_path
    snake_case.gsub(/::/, "/")
  end  
  
  # The reverse of +camelize+. Makes an underscored form from the expression in the string.
  #
  # Changes '::' to '/' to convert namespaces to paths.
  #
  # @example
  #   "ActiveRecord".underscore #=> "active_record"
  #   "ActiveRecord::Errors".underscore #=> active_record/errors
  #
  def underscore
    self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end   
end # class String


RBench.run(10_000) do
  report "String#underscore" do
    "CamelCaseString".underscore
    "SomeABitLongerCamel::CaseString".underscore
  end
  
  report "String#to_const_path" do
    "CamelCaseString".to_const_path
    "SomeABitLongerCamel::CaseString".to_const_path
  end

  report "String#snake_case" do
    "CamelCaseString".snake_case
    "SomeABitLongerCamelCaseString".snake_case
  end
end