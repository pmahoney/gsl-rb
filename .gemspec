# -*- encoding: utf-8 -*-
require 'rubygems' unless Object.const_defined?(:Gem)
$:.push File.dirname(__FILE__) + "/lib"
require 'gsl'
 
Gem::Specification.new do |s|
  s.name        = "gsl-rb"
  s.version     = GSL::VERSION
  s.authors     = ["Patrick Mahoney"]
  s.email       = "pat@polycrystal.org"
  s.homepage    = "http://github.com/pmahoney/gsl-rb"
  s.summary     = "A Ruby wrapper around GSL using FFI"
  s.description =  "Access GSL from Ruby, JRuby, others."
  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency 'ffi', '~> 1.0'

  s.add_development_dependency 'bacon', '>= 1.1.0'

  s.files = Dir.glob(%w[lib/**/*.rb [A-Z]*.{txt,rdoc}]) + %w{Rakefile .gemspec}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
  s.license = 'MIT'
end
