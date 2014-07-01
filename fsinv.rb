#!/usr/bin/env ruby

require 'mime/types'
require 'filemagic'
require 'json'

# use this if you see a KB as 2^10 bits
#$BYTES_IN_KiB = 2**10
#$BYTES_IN_MiB = 2**20
#$BYTES_IN_GiB = 2**30
#$BYTES_IN_TiB = 2**40

# these define a KB as 1000 bits
$BYTES_IN_KB = 10**3
$BYTES_IN_MB = 10**6
$BYTES_IN_GB = 10**9
$BYTES_IN_TB = 10**12

$fm = FileMagic.new # we will need this quite a lot

def sanitize_string(string)
  string = string.encode("UTF-16BE", :invalid=>:replace, :replace=>"_").encode("UTF-8")
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

class FileDefinition
  attr_accessor :bytes,:path,:mime_type,:type_description
  def initialize(path, bytes = nil)
    @path = path
    if bytes.nil?
      
      @bytes = 0
      begin
        @bytes = File.size(path)
      rescue Exception => e
        puts("exception getting size for file: #{path}")
      end
    else
      @bytes = bytes
    end
    
    begin 
      #@mime_type = `file -b --mime #{path}`
      @mime_type = MIME::Types.type_for(path)
      @type_description = $fm.file(@path)
    rescue ArgumentError # if this happens you should definitly repair some file names
      puts "type information unavailable - invalid symbol in path: #{@path}"
      @mime_type = "unavailable"
      @type_description = "unavailable"
    end
  end
    
  def to_json()
    begin 
      p = sanitize_string(@path)
      return "\{ \"type\" : \"file\", \"path\" : \"#{p}\", \"bytes\" : \"#{@bytes}\", \"mime_type\" : \"#{@mime_type.join(', ')}\", \"type_description\" : \"#{@type_description}\" \}"
    rescue ArgumentError
      puts "Invalid symbol in path: #{@path}"
      return ""
    end
  end
end

class DirectoryDefinition
  attr_accessor :path,:bytes,:file_list,:file_count
  def initialize(path, size, file_list)
    @path, @bytes, @file_list = path, size, file_list, @file_count = 0
  end
  
  def to_json()
    #files = "["
    files = []
    @file_list.each {|f|
      #unless files.empty?
      #  files += ", "
      #end
      #files = files + f.to_json()
      files << f.to_json()
    }
    #files += "]"
    begin 
      p = sanitize_string(@path)
      return "\{ \"type\" : \"directory\", \"path\" : \"#{p}\", \"bytes\" : \"#{@bytes}\", \"files\" : [ #{files.join(", ")} ] \}"
    rescue ArgumentError
      puts "Invalid symbol in path: #{@path}"
      return "" # do not return invalid dirs
    end
  end
end

#returns DirectoryDefinition object
def define_folder(folder_path)
  curr_dir = DirectoryDefinition.new(folder_path, 0, [])
  
  search_string = File.join(folder_path,'*')
  puts("search string: #{search_string}")
  
  wd_files = Dir.glob(search_string)
    
  wd_files.each{ |file|
    
    if File.directory?(file) && File.extname(file) != '.app'
      sub_folder = define_folder(file)
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

dir_path = ARGV[0]

main_dir = define_folder(dir_path)
size = main_dir.bytes
puts("directory info:")
puts("path: #{main_dir.path}")
puts("size: #{get_size_string(size)} (#{size} Bytes)")
puts("files: #{main_dir.file_list.length}")

#main_dir.file_list.each { |file|
#  puts("\t#{file.path} (#{file.get_size_string()})")
#}

#puts("json:")
puts("writing json to ./file_structure.json")
File.open("file_structure.json", 'w') {|f| 
  #json_str = main_dir.to_json()
  json_str = JSON.pretty_generate(JSON.parse(main_dir.to_json()))
  f.write(json_str) 
}
#puts(main_dir.to_json())
