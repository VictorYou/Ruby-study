# encoding: utf-8
require 'date'

# Determine the current version of the software
version = '1.0.6'

Gem::Specification.new do |spec|
  spec.name        = 'get_build'
  spec.version     = version
  spec.executables << 'get_builds.rb'
  spec.homepage    = ''
  spec.summary     = 'obtain build info'
  spec.description = <<-EOS
    it downloads web pages and takes certain build info and save to csv files
  EOS
  spec.author = 'You Victor'
  spec.email = "victoryou29@gmail.com"
  spec.platform = Gem::Platform::RUBY
  spec.bindir = 'bin'
  spec.files = Dir.glob(['bin/**/*',
                         'lib/**/*'])
  spec.required_ruby_version = '>= 2.3.1'
  spec.date = DateTime.now
  spec.license = 'Nonstandard'
end
