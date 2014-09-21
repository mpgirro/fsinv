# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fsinv'

Gem::Specification.new do |spec|
  spec.name        = 'fsinv'
  spec.version     = Fsinv::VERSION
  spec.date        = '2014-09-21'
  spec.summary     = "file system inventory tool"
  spec.description = "fsinv indexes file systems. It creates a complex inventory of one or more file system hierarchies and supports various output formats like JSON, YAML, XML, binary (ruby marshall dump) and SQLite3 db (via active_record). There is support for OSX extended file attribute tags, md5 hash and crc32 checksums."
  spec.author      = "Maximilian Irro"
  spec.email       = 'max@disposia.org'
  spec.files       = `git ls-files -z`.split("\x0")
  spec.executables = ['fsinv']
  spec.homepage    = 'https://github.com/mpgirro/fsinv'
  spec.license     = 'MIT'
  
  spec.require_paths = ['lib']
   
  spec.required_ruby_version = '>= 1.9.3'  
  spec.add_dependency 'activerecord', '~> 3.2', '>=3.2.12'
  spec.add_dependency 'mime-types', '~> 2.2', '>= 1.21'
  spec.add_dependency 'nokogiri', '~> 1.6', '>= 1.6.2.1'
  spec.add_dependency 'ruby-filemagic', '~> 0.6', '>= 0.6.0'
  spec.add_dependency 'sqlite3', '~> 1.3', '>= 1.3.7'
  spec.add_dependency 'ffi-xattr', '~> 0.1', '>= 0.1.2'
  spec.add_dependency 'digest-crc', '~> 0.4', '>= 0.4.1'
end