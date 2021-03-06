# -*- ruby -*-

require 'rake'
require 'rubygems/package_task'
require 'rdoc/task'
require 'rake/testtask'

def gemspec
  @gemspec ||= eval(File.read('.gemspec'), binding, '.gemspec')
end

desc 'Run the tests'
task :default => [:test]

Rake::TestTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.libs.push 'spec'
end

desc 'Compile documentation with RDoc'
task :doc => [:rdoc]

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/'
  rdoc.options += gemspec.rdoc_options
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.add ['README.rdoc', 'COPYING', 'lib/**/*.rb']
end

Gem::PackageTask.new(gemspec) do |p|
  p.need_tar = true
  p.gem_spec = gemspec
end

desc 'Install the current version of the gem locally'
task :install => [:package] do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

task :uninstall do
  sh %{gem uninstall #{gemspec.name} -v #{gemspec.version}}
end
