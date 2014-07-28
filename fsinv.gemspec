Gem::Specification.new do |s|
  s.name        = 'fsinv'
  s.version     = '0.0.1'
  s.date        = '2014-07-28'
  s.summary     = "file system inventory tool"
  s.description = "fsinv is used to index file system. It creates a complex inventory of one or more file system hierarchies and supports output formats like JSON, YAML, XML, binary (ruby marshall dump) and SQLite3 db (via active_record)."
  s.author      = "Maximilian Irro"
  s.email       = 'max@disposia.org'
  s.files       = ["lib/hola.rb","lib/fsinv/directorydefinition.rb","lib/fsinv/filedefinition.rb","lib/fsinv/fsinventory.rb","lib/fsinv/lookuptable.rb"]
  s.homepage    = 'https://github.com/mpgirro/fsinv'
  s.license     = 'MIT'
end