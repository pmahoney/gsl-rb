# -*- encoding: utf-8 -*-
require 'rubygems' unless Object.const_defined?(:Gem)
$:.push File.dirname(__FILE__) + "/lib"
require 'gsl/version'
 
Gem::Specification.new do |s|
  s.name        = "gsl-rb"
  s.version     = GSL::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Patrick Mahoney"]
  s.email       = "pat@polycrystal.org"
  s.homepage    = "http://github.com/pmahoney/gsl-rb"
  s.summary     = "A Ruby wrapper around GSL using FFI"
  s.description =  "Access GSL from Ruby, JRuby, others. with math functions, vector and matrix manipulation."
  s.required_rubygems_version = ">= 1.3.6"
  s.rdoc_options += ['--quiet', '--title', 'GSL for Ruby via FFI', '--main', 'README.rdoc', '--inline-source']

  s.add_dependency 'ffi', '~> 1.0'
  s.add_development_dependency 'bacon', '>= 1.1.0'

  s.files = Dir.glob(%w[lib/**/*.rb spec/**/*.rb [A-Z]*.{txt,rdoc}])
  s.files += %w{Rakefile .gemspec COPYING}
  s.extra_rdoc_files = ["README.rdoc", "COPYING"]
  s.license = 'MIT'
end
