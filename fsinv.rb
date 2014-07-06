#!/usr/bin/env ruby
# encoding: utf-8

# author: Maximilian Irro <max@disposia.org>, 2014

require 'mime/types'
begin
  require 'filemagic'
rescue
  puts "gem 'filemagic' required. Install using 'gem install ruby-filemagic'"
  puts "If you have trouble on OSX you may ned to run 'brew install libmagic' before"
  exit
end
require 'pathname'
require 'optparse'

# use these if you find a KB to be 2^10 bits
#BYTES_IN_KB = 2**10
#BYTES_IN_MB = 2**20
#BYTES_IN_GB = 2**30
#BYTES_IN_TB = 2**40

# these define a KB as 1000 bits
BYTES_IN_KB = 10**3
BYTES_IN_MB = 10**6
BYTES_IN_GB = 10**9
BYTES_IN_TB = 10**12

$IGNORE_FILES = ['.AppleDouble','.Parent','.DS_Store','Thumbs.db','__MACOSX']
$PSEUDO_FILES = ['.app', '.bundle', '.mbox', '.plugin', '.sparsebundle'] # look like files on osx, are folders in truth

def sanitize_string(string)
  string = string.encode("UTF-16BE", :invalid=>:replace, :undef => :replace, :replace=>"?").encode("UTF-8")
  pattern = /\"/
  string = string.gsub(pattern, "\\\"") # escape double quotes in string
  return string
end

def pretty_bytes_string(bytes)
  return "%.3f TB" % (bytes.to_f / BYTES_IN_TB) if bytes > BYTES_IN_TB
  return "%.3f GB" % (bytes.to_f / BYTES_IN_GB) if bytes > BYTES_IN_GB
  return "%.3f MB" % (bytes.to_f / BYTES_IN_MB) if bytes > BYTES_IN_MB
  return "%.3f KB" % (bytes.to_f / BYTES_IN_KB) if bytes > BYTES_IN_KB
  return "#{bytes} B"
end

class LookupTable
  
  attr_accessor :descr_map, :idcursor
  
  def initialize()
    @descr_map = Hash.new
    @idcursor = 0
    self.add("unavailable")
  end  
  
  def contains?(descr)
    if descr == ""
      return false
    else
      return @descr_map.has_value?(descr)
    end
  end
  
  def add(descr)
    if descr != ""
      @descr_map[idcursor] = descr
      @idcursor += 1
    end
  end
  
  def getid(descr)
    if descr == ""
      return 0
    else
      return @descr_map.key(descr)
    end
  end
  
  def getdescr(id)
    return @descr_map[id]
  end
  
  def to_a()
    table_arr = []
    @descr_map.each do | id, descr | 
      table_arr << {"id" => id, "description" => descr}
    end
    return table_arr
  end
  
  def as_json(options = { })
    return to_a
  end
  
  def to_json(*a)
    return as_json.to_json(*a)
  end
  
  def marshal_dump
    return {'descr_map' => descr_map, 'idcursor' => idcursor}
  end

  def marshal_load(data)
    self.descr_map = data['descr_map']
    self.idcursor = data['idcursor']
  end
  
end # LookupTable

class FileDefinition
  
  attr_accessor :path,:bytes,:ctime,:mtime,:mime_id,:kind_id
  
  def initialize(path, typecheck = true)
    @path = path
    @bytes = 0
    begin
      @bytes = File.size(@path)
    rescue 
      puts "error: exception getting size for file #{path}" unless $options[:silent]
    end
    
    begin 
      @ctime = File.ctime(path)
    rescue 
      puts "error getting creation time for file #{path}" unless $options[:silent]
    end
    
    begin 
      @mtime = File.mtime(path)
    rescue 
      puts "error getting modification time for file #{path}" unless $options[:silent]
    end
    
    if typecheck
      begin
        #@mime = `file -b --mime #{path}`
        description = MIME::Types.type_for(@path).join(', ')
        $mime_tab.add(description) unless $mime_tab.contains?(description)
        @mime_id = $mime_tab.getid(description)
      rescue ArgumentError # if this happens you should definitly repair some file names
        @mime_id = 0
      end
    
      begin 
        description = sanitize_string($fmagic.file(@path))
        $kind_tab.add(description) unless $kind_tab.contains?(description)
        @kind_id = $kind_tab.getid(description)
      rescue
        puts "error: file kind information unavailable" unless $options[:silent]
        @kind_id = 0
      end
    else
      @mime_id = 0
      @kind_id = 0
    end
  end
  
  def to_hash()
    p = sanitize_string(@path) rescue "path encoding broken" # there can be ArgumentError and UndefinedConversionError
    return {"type" => "file","path" => p,"bytes" => bytes, 'ctime' => ctime, 'mtime' => mtime, "mime_id" => mime_id, "kind_id" => kind_id}
  end
  
  def as_json(options = { })
    return to_hash
  end
    
  def to_json(*a)
    return as_json.to_json(*a)
  end
  
  def marshal_dump
    return {"path" => path, "bytes" => bytes, 'ctime' => ctime, 'mtime' => mtime, "mime_id" => mime_id, "kind_id" => kind_id}
  end

  def marshal_load(data)
    self.path = data['path']
    self.bytes = data['bytes']
    self.ctime = data['ctime']
    self.mtime = data['mtime']
    self.mime_id = data['mime_id']
    self.kind_id = data['kind_id']
  end
  
end # FileDefinition

class DirectoryDefinition
  
  attr_accessor :path,:bytes,:ctime,:mtime,:file_count,:item_count,:file_list
  
  def initialize(path)
    @path = path
    @bytes = 0
    @file_list = []
    @file_count = 0 
    @item_count = 1
    
    begin 
      @ctime = File.ctime(path)
    rescue 
      puts "error getting creation time for directory #{path}" unless $options[:silent]
    end
    
    begin 
      @mtime = File.mtime(path)
    rescue 
      puts "error getting modification time for directory #{path}" unless $options[:silent]
    end
  end
  
  def as_json(options = { })
    p = sanitize_string(@path) rescue "path encoding broken" # there can be ArgumentError and UndefinedConversionError
    return {"type" => "directory", "path" => p, "bytes" => bytes, 'ctime' => ctime, 'mtime' => mtime, "file_count" => file_count, "item_count" => item_count, "file_list" => file_list}
  end
  
  def to_json(*a)
    return as_json.to_json(*a)
  end
  
  def marshal_dump
    return {'path' => path, 'bytes' => bytes, 'ctime' => ctime, 'mtime' => mtime, 'file_count' => file_count, 'item_count' => item_count, 'file_list' => file_list}
  end

  def marshal_load(data)
    self.path = data['path']
    self.bytes = data['bytes']
    self.ctime = data['ctime']
    self.mtime = data['mtime']
    self.file_count = data['file_count']
    self.item_count = data['item_count']
    self.file_list = data['file_list']
  end
end # DirectoryDefinition



#returns DirectoryDefinition object
def parse(folder_path, pseudofile = false)
  
  if $PSEUDO_FILES.include?(File.extname(folder_path)) # stuff like .app, .bundle, .mbox etc.
    puts "processing pseudofile #{folder_path}" unless pseudofile || $options[:silent]
    pseudofile = true
  else
    puts "processing #{folder_path}/*" unless pseudofile || $options[:silent]
  end
  
  curr_dir = DirectoryDefinition.new(folder_path)
  
  begin
    Pathname.new(folder_path).children.each { |f| 
      file = f.to_s.encode("UTF-8")
      if $IGNORE_FILES.include?(File.basename(file))
        # do nothing
      elsif File.directory?(file) 
        sub_folder = parse(file, pseudofile)
        curr_dir.bytes += sub_folder.bytes
        curr_dir.file_list << sub_folder unless pseudofile
        curr_dir.item_count += sub_folder.item_count unless pseudofile
      else
        puts "processing #{file}" if $options[:verbose] && !pseudofile && $options[:silent].nil?
        sub_file = FileDefinition.new(file, !pseudofile)
        curr_dir.bytes += sub_file.bytes
        curr_dir.file_list << sub_file unless pseudofile
        curr_dir.item_count += 1 unless pseudofile
      end
    }
  rescue
    puts "permission denied: #{curr_dir}" unless $options[:silent]
  end

  return curr_dir
end # parse()

class FsInventory
  
  attr_accessor :kind_tab, :mime_tab, :file_structure
  
  def initialize(kind_tab, mime_tab, file_structure)
    @kind_tab = kind_tab
    @mime_tab  = mime_tab
    @file_structure = file_structure
  end
  
  def root_path()
    return @file_structure.path
  end  
  
  def size()
    return file_structure.bytes
  end
  
  def to_hash()
    return {"kind_tab" => kind_tab, "mime_tab" => mime_tab, "file_structure" => file_structure}
  end
  
  def as_json(options = { })
    return to_hash
  end
  
  def to_json(*a)
    as_json.to_json(*a)
  end
  
  def marshal_dump
    return to_hash
  end

  def marshal_load(data)
    self.kind_tab = data['kind_tab']
    self.mime_tab = data['mime_tab']
    self.file_structure = data['file_structure']
  end
  
end

def filestructure_to_xml(xml, defobj)
  case defobj
  when DirectoryDefinition
    xml.directory{
      xml.path(defobj.path)
      xml.bytes(defobj.bytes)
      xml.file_count(defobj.file_count)
      xml.item_count(defobj.item_count)
      xml.file_list {
        defobj.file_list.each do |child|
          filestructure_to_xml(xml, child)
        end
      }
    }
  when FileDefinition
    xml.file{
      xml.path(defobj.path)
      xml.bytes(defobj.bytes)
      xml.mime_id(defobj.mime_id)
      xml.kind_id(defobj.kind_id)
    }
  end 
end

def filestructure_to_sqlite(db,defobj,parent_rowid)
  case defobj
  when DirectoryDefinition
    db.execute("INSERT INTO directory(path, bytes, ctime, mtime, file_count, item_count, parent) 
                VALUES ('#{defobj.path}', #{defobj.bytes}, '#{defobj.ctime}', '#{defobj.mtime}', 
                #{defobj.file_count}, #{defobj.item_count},#{parent_rowid})")
    rowid = db.execute("SELECT last_insert_rowid() AS rowid").first.first # return a 2-dim array   
    defobj.file_list.each do |child|
      filestructure_to_sqlite(db,child,rowid)
    end
  when FileDefinition
    db.execute("INSERT INTO file(path, bytes, ctime, mtime, mime_id, kind_id, parent) 
                VALUES ('#{defobj.path}',#{defobj.bytes}, '#{defobj.ctime}',
                '#{defobj.mtime}',#{defobj.mime_id},#{defobj.kind_id},#{parent_rowid})")
  end
end

if __FILE__ == $0

  DEFAULT_NAME = "inventory"
  USAGE = "Usage: fsinv.rb basepath [options]"

  $options = {}
  OptionParser.new do |opts|
    opts.banner = USAGE
    opts.separator ""
    opts.separator "Specific options:"

    opts.on("-a", "--all", "Save in all formats to the default destinations. Equal to -b -j -q -x -y. Use -n to change the file names") do |all_flag|
      $options[:binary]  = true
      $options[:json]    = true
      $options[:sql]     = true
      $options[:xml]     = true
      $options[:yaml]    = true
    end
  
    opts.on("-b", "--binary [FILE]", "Dump iventory data stuctures in binary format. Default destination is #{DEFAULT_NAME}.bin") do |binary_file|
      $options[:binary] = true
      $options[:binary_file] = binary_file
    end
  
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  
    opts.on("-j", "--json [FILE]", "Save inventory in JSON file format. Default destination is #{DEFAULT_NAME}.json") do |json_file|
      $options[:json] = true
      $options[:json_file] = json_file
    end
  
    opts.on("-n", "--name INV_NAME", "Name of the inventory. This will change the name of the output files. 
                                     Default is '#{DEFAULT_NAME}'. Specific targets for file formats will overwrite this.") do |name|
      $options[:name] = name
    end
  
    opts.on("-p", "--print FORMAT", [:json, :yaml, :xml], "Print a format to stdout (json|yaml|xml)") do |format|
      $options[:print] = true
      $options[:print_format] = format
    end
  
    opts.on("-q", "--sql [FILE]", "Save inventory as SQLite database. Default destination is #{DEFAULT_NAME}.db") do |sql_file|
      $options[:sql] = true
      $options[:sql_file] = sql_file 
    end
  
    opts.on("-s", "--silent", "Run in silent mode. No output or non-critical error messages will be printed") do |s|
      $options[:silent] = s
    end
  
    opts.on("-v", "--verbose", "Run verbosely. This will output processed filenames and error messages too") do |v|
      $options[:verbose] = v
    end
  
    opts.on("-x", "--xml [FILE]", "Save inventory in XML file format. Default destination is #{DEFAULT_NAME}.xml") do |xml_file|
      $options[:xml] = true
      $options[:xml_file] = xml_file 
    end
  
    opts.on("-y", "--yaml [FILE]", "Save inventory in YAML file format. Default destination is #{DEFAULT_NAME}.yaml") do |yaml_file|
      $options[:yaml] = true
      $options[:yaml_file] = yaml_file
    end
  end.parse! # do the parsing. do it now!

  #p $options
  #p ARGV

  if ARGV[0].nil? 
    puts "No basepath provided"
    puts USAGE
    exit
  elsif !File.directory?(ARGV[0])
    puts "Not a directory"
    puts USAGE
    exit
  elsif ARGV.length > 1
    puts "Too many arguments"
    p ARGV
    puts USAGE
    exit 
  end

  main_path = ARGV[0]

  $fmagic = FileMagic.new 
  $kind_tab = LookupTable.new # magic file descriptions
  $mime_tab = LookupTable.new

  fs_tree = parse(main_path)

  inventory = FsInventory.new($kind_tab, $mime_tab, fs_tree)
  
  unless $options[:silent]
    size = inventory.size
    puts "info:"
    puts "path: #{fs_tree.path}"
    puts "size: #{pretty_bytes_string(size)} (#{size} Bytes)"
    puts "files: #{fs_tree.file_list.length}"
    puts "items: #{fs_tree.item_count}"
  end

  # this is the default output
  unless ($options[:binary]||$options[:sql]||$options[:xml]||$options[:yaml]) && $options[:json].nil?
    if $options[:json_file].nil?
      if $options[:name].nil?
        $options[:json_file] = "#{DEFAULT_NAME}.json"
      else 
        $options[:json_file] = "#{$options[:name]}.json"
      end
    end
    puts "writing JSON to #{$options[:json_file]}" unless $options[:silent]
    json_data = JSON.parse(inventory.to_json, :max_nesting => 100)
    json_data = JSON.pretty_generate(json_data, :max_nesting => 100) 
    begin 
      require 'json'
      file = File.open($options[:json_file], 'w') 
      file.write(json_data)
    rescue LoadError
      puts "gem 'json' needed for JSON creation. Install using 'gem install json'"
    rescue
      puts "error writing JSON file"
    ensure
      file.close unless file.nil?
    end
  end

  if $options[:yaml]
    
    if $options[:yaml_file].nil?
      if $options[:name].nil?
        $options[:yaml_file] = "#{DEFAULT_NAME}.yaml"
      else 
        $options[:yaml_file] = "#{$options[:name]}.yaml"
      end
    end
    puts "writing YAML to #{$options[:yaml_file]}" unless $options[:silent]
    begin
      require 'yaml'  
      yml_data = YAML::dump(inventory)
      file = File.open($options[:yaml_file], 'w') 
      file.write(yml_data)
    rescue LoadError
      puts "gem 'yaml' needed for YAML creation. Install using 'gem install yaml'"
    rescue
      puts "error writing YAML file"
    ensure
      file.close unless file.nil?
    end
  end
  
  if $options[:binary]
    if $options[:binary_file].nil?
      if $options[:name].nil?
        $options[:binary_file] = "#{DEFAULT_NAME}.bin"
      else 
        $options[:binary_file] = "#{$options[:name]}.bin"
      end
    end
    puts "writing binary dump to #{$options[:binary_file]}" unless $options[:silent]
    begin
      file = File.open($options[:binary_file], 'wb') 
      file.write(Marshal.dump(inventory))
    rescue
      puts "error writing binary dump file"
    ensure
      file.close unless file.nil?
    end
  end
  
  if $options[:sql]
    
    if $options[:sql_file].nil?
      if $options[:name].nil?
        $options[:sql_file] = "#{DEFAULT_NAME}.db"
      else 
        $options[:sql_file] = "#{$options[:name]}.db"
      end
    end

    puts "writing SQL dump to #{$options[:sql_file]}" unless $options[:silent]
    `rm #{$options[:sql_file]}`

    begin
      require 'sqlite3'
      db = SQLite3::Database.new("#{$options[:sql_file]}")
      db.execute "CREATE TABLE IF NOT EXISTS mime_tab(id INTEGER PRIMARY KEY, description TEXT)"
      db.execute "CREATE TABLE IF NOT EXISTS kind_tab(id INTEGER PRIMARY KEY, description TEXT)"
      db.execute "CREATE TABLE IF NOT EXISTS directory(id INTEGER PRIMARY KEY, path TEXT, 
                  bytes INTEGER, ctime TEXT, mtime TEXT, file_count INTEGER, item_count INTEGER, 
                  parent REFERENCES directory(rowid))" # rowid is an implicid column of sqlite
      db.execute "CREATE TABLE IF NOT EXISTS file(id INTEGER PRIMARY KEY, path TEXT, 
                  bytes INTEGER, ctime TEXT, mtime TEXT, mime_id REFERENCES mime_tab(id), 
                  kind_id REFERENCES kind_tab(id), parent REFERENCES directory(rowid))" # rowid is an implicid column of sqlite
                  
      inventory.mime_tab.descr_map.each { |id, descr| db.execute("INSERT INTO mime_tab(id,description) VALUES (#{id},'#{descr}')") }
      inventory.kind_tab.descr_map.each { |id, descr| db.execute("INSERT INTO kind_tab(id,description) VALUES (#{id},'#{descr}')") }
      
      filestructure_to_sqlite(db, inventory.file_structure, 1) # sqlite indizes start with 1
      
    rescue SQLite3::Exception => e 
        puts e
    rescue LoadError
      puts "gem 'sqlite3' needed for SQLite DB creation. Install using 'gem install sqlite3'"
    ensure
        db.close if db
    end
  end

  if $options[:xml]
    
    if $options[:xml_file].nil?
      if $options[:name].nil?
        $options[:xml_file] = "#{DEFAULT_NAME}.xml"
      else 
        $options[:xml_file] = "#{$options[:name]}.xml"
      end
    end
    puts "writing XML to #{$options[:xml_file]}" unless $options[:silent]
    begin
      require 'nokogiri'
      builder = Nokogiri::XML::Builder.new do |xml| 
        xml.inventory{
          #output the magic tab
          xml.kind_tab{
            inventory.kind_tab.descr_map.each{ |id, descr|
              xml.item{
                xml.id(id)
                xml.description(descr)
              }
            } 
          }
          #ouput the mime tab
          xml.kind_tab{
            inventory.mime_tab.descr_map.each{ |id, descr|
              xml.item{
                xml.id(id)
                xml.description(descr)
              }
            } 
          }
          #output the file structure
          xml.file_structure{
            filestructure_to_xml(xml, inventory.file_structure)
          } 
        }
      end
    
      file = File.open($options[:xml_file], 'w') 
      file.write(builder.to_xml)
    rescue LoadError
      puts "gem 'nokogiri' needed for XML creation. Install using 'gem install nokogiri'"
    rescue
      puts "error writing XML file"
    ensure
      file.close unless file.nil?
    end
  end

end
