#!/usr/bin/env ruby
# encoding: utf-8

require 'mime/types'
require 'filemagic'
require 'json'
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

class DescriptionTable
  
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
  
  attr_accessor :bytes,:path,:mime,:description_id
  
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
      @mime = MIME::Types.type_for(@path)
    rescue ArgumentError # if this happens you should definitly repair some file names
      @mime = []
    end
    
    begin 
      description = sanitize_string($fmagic.file(@path))
      if !$description_tab.contains?(description)
        $description_tab.add(description)
      end
      #@description = magic_descr
      @description_id = $description_tab.getid(description)
    rescue
      puts "file magic information unavailable"
      @description_id = 0
    end
  end
    
  def to_json()
    begin 
      p = sanitize_string(@path)
      json_item = "\{ \"type\" : \"file\", \"path\" : \"#{p}\", \"bytes\" : \"#{@bytes}\", \"mime\" : \"#{@mime.join(', ')}\", \"description_id\" : #{@description_id} \}"
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
  
  Pathname.new(folder_path).children.each { |f| 
    
    file = f.to_s.encode("UTF-8")
    
    #if File.directory?(file) && File.extname(file) != '.app'
    if File.directory?(file)
      sub_folder = parse(file)
      curr_dir.file_list << sub_folder
      curr_dir.bytes += sub_folder.bytes
    else
      sub_file = FileDefinition.new(file)
      curr_dir.bytes += sub_file.bytes
      curr_dir.file_list << sub_file
    end
  }
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
$description_tab = DescriptionTable.new

main_dir = parse(main_path)
size = main_dir.bytes
puts("directory info:")
puts("path: #{main_dir.path}")
puts("size: #{get_size_string(size)} (#{size} Bytes)")
puts("files: #{main_dir.file_list.length}")

puts "writing JSON to ./file_structure.json" 
File.open("file_structure.json", 'w') {|f| 
  #json_str = main_dir.to_json()
  simple_json_str = "\{ \"description_table\" : #{$description_tab.to_json}, \"file_structure\" : #{main_dir.to_json} \}"
  pretty_json_str = JSON.pretty_generate(JSON.parse(simple_json_str, :max_nesting => 100))
  f.write(pretty_json_str) 
}

if $broken_paths.length > 0
  puts "writing broken links to ./broken_links.txt"
  File.open("broken_links.txt", 'w') {|f| 
    f.write($broken_paths.join("\n")) 
  }
end
