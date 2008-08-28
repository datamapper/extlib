#!/usr/bin/env ruby
require 'pathname'
require 'rubygems'
require 'rake'
require "rake/clean"
require "rake/gempackagetask"
require "fileutils"
require Pathname('spec/rake/spectask')
require Pathname('lib/extlib/version')

ROOT = Pathname(__FILE__).dirname.expand_path

##############################################################################
# Package && release
##############################################################################
RUBY_FORGE_PROJECT  = "extlib"
PROJECT_URL         = "http://extlib.rubyforge.org"
PROJECT_SUMMARY     = "Support library for DataMapper and Merb."
PROJECT_DESCRIPTION = PROJECT_SUMMARY

AUTHOR = "Sam Smoot"
EMAIL  = "ssmoot@gmail.com"

GEM_NAME    = "extlib"
PKG_BUILD   = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
GEM_VERSION = Extlib::VERSION + PKG_BUILD

RELEASE_NAME    = "REL #{GEM_VERSION}"

require "lib/extlib/tasks/release"

spec = Gem::Specification.new do |s|
  s.name         = GEM_NAME
  s.version      = GEM_VERSION
  s.platform     = Gem::Platform::RUBY
  s.author       = AUTHOR
  s.email        = EMAIL
  s.homepage     = PROJECT_URL
  s.summary      = PROJECT_SUMMARY
  s.description  = PROJECT_DESCRIPTION
  s.require_path = "lib"
  s.files        = ["LICENSE", "README.txt", "Rakefile"] + Dir["lib/**/*"]

  # rdoc
  s.has_rdoc         = false
  s.extra_rdoc_files = ["LICENSE", "README.txt"]

  # Dependencies
  s.add_dependency "english", ">=0.2.0"
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc 'Remove all package, docs and spec products'
task :clobber_all => %w[ clobber_package clobber_doc extlib:clobber_spec ]

##############################################################################
# Specs and continous integration
##############################################################################
task :default => 'extlib:spec'
task :spec    => 'extlib:spec'

namespace :extlib do
  Spec::Rake::SpecTask.new(:spec) do |t|
    t.spec_opts << '--format' << 'specdoc' << '--colour'
    t.spec_opts << '--loadby' << 'random'
    t.spec_files = Pathname.glob(ENV['FILES'] || 'spec/**/*_spec.rb')

    begin
      t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
      t.rcov_opts << '--exclude' << 'spec'
      t.rcov_opts << '--text-summary'
      t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
    rescue Exception
      # rcov not installed
    end
  end
end


##############################################################################
# Documentation
##############################################################################
desc "Generate documentation"
task :doc do
  begin
    require 'yard'
    exec 'yardoc'
  rescue LoadError
    puts 'You will need to install the latest version of Yard to generate the
          documentation for extlib.'
  end
end

WINDOWS = (RUBY_PLATFORM =~ /win32|mingw|bccwin|cygwin/) rescue nil
SUDO    = WINDOWS ? '' : ('sudo' unless ENV['SUDOLESS'])


desc "Install #{GEM_NAME}"
task :install => :package do
  sh %{#{SUDO} gem install --local pkg/#{GEM_NAME}-#{GEM_VERSION} --no-update-sources}
end

if WINDOWS
  namespace :dev do
    desc 'Install for development (for windows)'
    task :winstall => :gem do
      system %{gem install --no-rdoc --no-ri -l pkg/#{GEM_NAME}-#{GEM_VERSION}.gem}
    end
  end
end

namespace :ci do

  task :prepare do
    rm_rf ROOT + "ci"
    mkdir_p ROOT + "ci"
    mkdir_p ROOT + "ci/doc"
    mkdir_p ROOT + "ci/cyclomatic"
    mkdir_p ROOT + "ci/token"
  end

  task :publish do
    out = ENV['CC_BUILD_ARTIFACTS'] || "out"
    mkdir_p out unless File.directory? out

    mv "ci/unit_rspec_report.html", "#{out}/unit_rspec_report.html"
    mv "ci/unit_coverage", "#{out}/unit_coverage"
    mv "ci/integration_rspec_report.html", "#{out}/integration_rspec_report.html"
    mv "ci/integration_coverage", "#{out}/integration_coverage"
    mv "ci/doc", "#{out}/doc"
    mv "ci/cyclomatic", "#{out}/cyclomatic_complexity"
    mv "ci/token", "#{out}/token_complexity"
  end


  Spec::Rake::SpecTask.new("spec:unit" => :prepare) do |t|
    t.spec_opts = ["--format", "specdoc", "--format", "html:#{ROOT}/ci/unit_rspec_report.html", "--diff"]
    t.spec_files = Pathname.glob(ROOT + "spec/unit/**/*_spec.rb")
    unless ENV['NO_RCOV']
      t.rcov = true
      t.rcov_opts << '--exclude' << "spec,gems"
      t.rcov_opts << '--text-summary'
      t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
      t.rcov_opts << '--only-uncovered'
    end
  end

  Spec::Rake::SpecTask.new("spec:integration" => :prepare) do |t|
    t.spec_opts = ["--format", "specdoc", "--format", "html:#{ROOT}/ci/integration_rspec_report.html", "--diff"]
    t.spec_files = Pathname.glob(ROOT + "spec/integration/**/*_spec.rb")
    unless ENV['NO_RCOV']
      t.rcov = true
      t.rcov_opts << '--exclude' << "spec,gems"
      t.rcov_opts << '--text-summary'
      t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
      t.rcov_opts << '--only-uncovered'
    end
  end

  task :spec do
    Rake::Task["ci:spec:unit"].invoke
    mv ROOT + "coverage", ROOT + "ci/unit_coverage"

    Rake::Task["ci:spec:integration"].invoke
    mv ROOT + "coverage", ROOT + "ci/integration_coverage"
  end

  task :doc do
    require 'yardoc'
    sh 'yardoc'
  end

  task :saikuro => :prepare do
    system "saikuro -c -i lib -y 0 -w 10 -e 15 -o ci/cyclomatic"
    mv 'ci/cyclomatic/index_cyclo.html', 'ci/cyclomatic/index.html'

    system "saikuro -t -i lib -y 0 -w 20 -e 30 -o ci/token"
    mv 'ci/token/index_token.html', 'ci/token/index.html'
  end
end

task :ci => ["ci:spec", "ci:doc", "ci:saikuro", :install, :publish]

##############################################################################
# Benchmarks
##############################################################################

namespace :benchmark do
  desc "Runs benchmarks"
  task :run do
    files = Dir["benchmarks/**/*.rb"]
    
    files.each do |f|
      system "ruby #{f}"
    end
  end  
end