#!/usr/bin/env ruby
# encoding: utf-8

require 'mime/types'
require 'filemagic'
require 'json'
require 'yaml'
require 'active_support/all' # to get to_xml()
require 'pathname'

# use these if you find a KB to be 2^10 bits
#$BYTES_IN_KiB = 2**10
#$BYTES_IN_MiB = 2**20
#$BYTES_IN_GiB = 2**30
#$BYTES_IN_TiB = 2**40

# these define a KB as 1000 bits
$BYTES_IN_KB = 10**3
$BYTES_IN_MB = 10**6
$BYTES_IN_GB = 10**9
$BYTES_IN_TB = 10**12

$IGNORE_FILES = ['.AppleDoube','.Parent','.DS_Store','Thumbs.db']

def sanitize_string(string)
  string = string.encode("UTF-16BE", :invalid=>:replace, :undef => :replace, :replace=>"_").encode("UTF-8")
  pattern = /\"/
  string = string.gsub(pattern, "\\\"") # escape double quotes in string
  return string
end

def get_size_string(bytes)
  if bytes > $BYTES_IN_TB
    return "%f TB" % (bytes.to_f / $BYTES_IN_TB)
  elsif bytes > $BYTES_IN_GB
    return "%f GB" % (bytes.to_f / $BYTES_IN_GB)
  elsif bytes > $BYTES_IN_MB
    return "%f MB" % (bytes.to_f / $BYTES_IN_MB)
  elsif bytes > $BYTES_IN_KB
    return "%f KB" % (bytes.to_f / $BYTES_IN_KB)
  else
    return "#{bytes} B"
  end
end

class LookupTable
  
  attr_accessor :descr_map, :idcursor
  
  def initialize()
    @descr_map = Hash.new
    @idcursor = 0
    self.add("unavailable")
  end  
  
  def contains?(descr)
    return @descr_map.has_value?(descr)
  end
  
  def add(descr)
    @descr_map[idcursor] = descr
    @idcursor += 1
  end
  
  def getid(descr)
    return @descr_map.key(descr)
  end
  
  def getdescr(id)
    return @descr_map[id]
  end
  
  def to_json()
    descr_arr = []
    @descr_map.each { | id, descr | 
      descr_arr << "\{ \"id\" : #{id}, \"description\" : \"#{descr}\" \}"
    }
    return "[ #{descr_arr.join(", ")} ]"
  end
  
end

class FileDefinition
  
  attr_accessor :bytes,:path,:mime_id,:magic_id
  
  def initialize(path, bytes = nil)
    
    @path = path
    puts "processing file: #{@path}"
    
    if bytes.nil?
      @bytes = 0
      begin
        @bytes = File.size(@path)
      rescue Exception => e
        puts("exception getting size for file: #{path}")
      end
    else
      @bytes = bytes
    end
    
    begin
      #@mime = `file -b --mime #{path}`
      #@mime = MIME::Types.type_for(@path)
      description = MIME::Types.type_for(@path).join(', ')
      if !$mime_tab.contains?(description)
        $mime_tab.add(description)
      end
      @mime_id = $mime_tab.getid(description)
    rescue ArgumentError # if this happens you should definitly repair some file names
      @mime_id = 0
    end
    
    begin 
      description = sanitize_string($fmagic.file(@path))
      if !$magic_tab.contains?(description)
        $magic_tab.add(description)
      end
      #@description = magic_descr
      @magic_id = $magic_tab.getid(description)
    rescue
      puts "file magic information unavailable"
      @magic_id = 0
    end
  end
    
  def to_json()
    begin 
      p = sanitize_string(@path)
      json_item = "\{ \"type\" : \"file\", \"path\" : \"#{p}\", \"bytes\" : \"#{@bytes}\", \"mime_id\" : #{@mime_id}, \"magic_id\" : #{@magic_id} \}"
      return json_item.force_encoding("utf-8")
    rescue ArgumentError
      puts "invalid symbol in path: #{@path}"
      $broken_paths << @path
      return "\{ \"type\" : \"argument error\" \}"
    rescue UndefinedConversionError
      puts "undefined conversion error"
      return "\{ \"type\" : \"conversion error\" \}"
    end
  end
end

class DirectoryDefinition
  
  attr_accessor :path,:bytes,:file_list,:file_count
  
  def initialize(path, size, file_list)
    @path, @bytes, @file_list = path, size, file_list, @file_count = 0, @children = []
    puts "processing dir:  #{@path}"
  end
  
  def to_json()
    files = []
    @file_list.each {|f|
      files << f.to_json()
    }
    begin 
      p = sanitize_string(@path)
      json_item = "\{ \"type\" : \"directory\", \"path\" : \"#{p}\", \"bytes\" : \"#{@bytes}\", \"files\" : [ #{files.join(", ")} ] \}"
      return json_item.force_encoding("utf-8")
    rescue ArgumentError
      puts "invalid symbol in path: #{@path}"
      $broken_paths << @path
      return "\{ \"type\" : \"argument error\" \}"
    rescue UndefinedConversionError
      puts "undefined conversion error"
      return "\{ \"type\" : \"conversion error\" \}"
    end
  end
end

#returns DirectoryDefinition object
def parse(folder_path)
  
  curr_dir = DirectoryDefinition.new(folder_path, 0, [])
  
  begin
    Pathname.new(folder_path).children.each { |f| 
      file = f.to_s.encode("UTF-8")
      if File.directory?(file) && File.extname(file) != '.app'
      #if File.directory?(file)
        sub_folder = parse(file)
        curr_dir.file_list << sub_folder
        curr_dir.bytes += sub_folder.bytes
      elsif $IGNORE_FILES.include?(File.basename(file))
        # do nothing
      else
        sub_file = FileDefinition.new(file)
        curr_dir.bytes += sub_file.bytes
        curr_dir.file_list << sub_file
      end
    }
  rescue
    puts "permission denied, skipping #{curr_dir}"
  end
  return curr_dir
end

dir_path = ''
if ARGV[0].nil? || !File.directory?(ARGV[0])
  puts("directory required.")
  return
end

main_path = ARGV[0]

$fmagic = FileMagic.new 
$broken_paths = []
$magic_tab = LookupTable.new # magic file descriptions
$mime_tab = LookupTable.new

main_dir = parse(main_path)
size = main_dir.bytes
puts("directory info:")
puts("path: #{main_dir.path}")
puts("size: #{get_size_string(size)} (#{size} Bytes)")
puts("files: #{main_dir.file_list.length}")



#json_str = main_dir.to_json()
json_str = "\{ \"magic_table\" : #{$magic_tab.to_json}, \"mime_table\" : #{$mime_tab.to_json}, \"file_structure\" : #{main_dir.to_json} \}"
json_data = JSON.parse(json_str, :max_nesting => 100)
yml_data = YAML::dump(json_data)

puts "writing JSON to inventory.json" 
json_file = File.open("inventory.json", 'w')
json_file.write(JSON.pretty_generate(json_data)) 

puts "writing YAML to inventory.yaml" 
yml_file = File.open("inventory.yaml", 'w')
yml_file.write(yml_data)

puts "writing XML to inventory.xml" 
xml_file = File.open("inventory.xml", 'w')
xml_file.write(json_data.to_xml(:root => :my_root))

#File.open("file_structure.yaml", 'w') {|f| 
#  yaml_str = "---\n #{$magic_tab.to_yaml} \n---\n "
#}

if $broken_paths.length > 0
  puts "writing broken links to ./broken_paths.txt"
  File.open("broken_links.txt", 'w') {|f| 
    f.write($broken_paths.join("\n")) 
  }
end
