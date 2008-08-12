#!/usr/bin/env ruby
require "rubygems"
require "rbench"

class String
  ##
  # @return <String> The path string converted to a constant name.
  #
  # @example
  #   "merb/core_ext/string".to_const_string #=> "Merb::CoreExt::String"
  def to_const_string
    gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
end # class String


# The original of this file was copied for the ActiveSupport project which is
# part of the Ruby On Rails web-framework (http://rubyonrails.org)
#
# Methods have been modified or removed. English inflection is now provided via
# the english gem (http://english.rubyforge.org)
#
# sudo gem install english
#
gem 'english', '>=0.2.0'
require 'english/inflect'

module Extlib
  module Inflection
    class << self
      # Take an underscored name and make it into a camelized name
      #
      # @example
      #   "egg_and_hams".classify #=> "EggAndHam"
      #   "post".classify #=> "Post"
      #
      def classify(name)
        camelize(singularize(name.to_s.sub(/.*\./, '')))
      end

      # By default, camelize converts strings to UpperCamelCase.
      #
      # camelize will also convert '/' to '::' which is useful for converting paths to namespaces
      #
      # @example
      #   "active_record".camelize #=> "ActiveRecord"
      #   "active_record/errors".camelize #=> "ActiveRecord::Errors"
      #
      def camelize(lower_case_and_underscored_word, *args)
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      end

      # The reverse of +camelize+. Makes an underscored form from the expression in the string.
      #
      # Changes '::' to '/' to convert namespaces to paths.
      #
      # @example
      #   "ActiveRecord".underscore #=> "active_record"
      #   "ActiveRecord::Errors".underscore #=> active_record/errors
      #
      def underscore(camel_cased_word)
        camel_cased_word.to_s.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
      
      def singularize(word)
        English::Inflect.singular(word)
      end

      def pluralize(word)
        English::Inflect.plural(word)
      end      
    end
  end # module Inflection
end # module Extlib


RBench.run(10_000) do
  report "Extlib::Inflection.camelize" do
    Extlib::Inflection.classify("some/hypothetic/module")
    Extlib::Inflection.classify("just_a_module")    
  end

  report "String#to_const_string" do
    "some/hypothetic/module".to_const_string
    "just_a_module".to_const_string
  end
end