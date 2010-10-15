# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'simple_taggable/version'

Gem::Specification.new do |s|
  s.name         = "simple_taggable"
  s.version      = SimpleTaggable::VERSION
  s.authors      = ["Sven Fuchs"]
  s.email        = "svenfuchs@artweb-design.de"
  s.homepage     = "http://github.com/svenfuchs/simple_taggable"
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files        = `git ls-files {app,lib}`.split("\n")
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_dependency 'activerecord'
  s.add_development_dependency 'railties'
  s.add_development_dependency 'test_declarative'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'sqlite3-ruby'
  s.add_development_dependency 'rails'
end
