#!/usr/bin/env ruby

require 'mime/types'
require 'filemagic'

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

def get_size_string(size_in_bytes)
  if size_in_bytes > $BYTES_IN_TB
    return "%f TB" % (size_in_bytes.to_f / $BYTES_IN_TB)
  elsif size_in_bytes > $BYTES_IN_GB
    return "%f GB" % (size_in_bytes.to_f / $BYTES_IN_GB)
  elsif size_in_bytes > $BYTES_IN_MB
    return "%f MB" % (size_in_bytes.to_f / $BYTES_IN_MB)
  elsif size_in_bytes > $BYTES_IN_KB
    return "%f KB" % (size_in_bytes.to_f / $BYTES_IN_KB)
  else
    return "#{size_in_bytes} B"
  end
end

class FileDefinition
  attr_accessor :size_in_bytes,:path,:mime_type,:description
  def initialize(path, size_in_bytes = nil)
    @path = path
    if size_in_bytes.nil?
      
      @size_in_bytes = 0
      begin
        @size_in_bytes = File.size(path)
      rescue Exception => e
        puts("exception getting size for file: #{path}")
      end
    else
      @size_in_bytes = size_in_bytes
    end
    
    #@mime_type = `file -b --mime #{path}`
    @mime_type = MIME::Types.type_for(path)
    
    @description = $fm.file(@path)
  end
    
  def to_json()
    begin 
      p = sanitize_string(@path)
      return "\{  
                  \"type\" : \"file\", 
                  \"path\" : \"#{p}\", 
                  \"size_in_bytes\" : \"#{@size_in_bytes}\", 
                  \"mime_type\" : \"#{@mime_type.join(', ')}\",
                  \"description\" : \"#{@description}\"
              \}"
    rescue ArgumentError
      puts "Invalid symbol in path: #{@path}"
      return ""
    end
  end
end

class DirectoryDefinition
  attr_accessor :path,:size_in_bytes,:file_list
  def initialize(path, size, file_list)
    @path, @size_in_bytes, @file_list = path, size, file_list
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
      return "\{ 
                \"type\" : \"directory\", 
                \"path\" : \"#{p}\", 
                \"size_in_bytes\" : \"#{@size_in_bytes}\", 
                \"files\" : [
                  #{files.join(",")}
                ]
              \}"
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
      curr_dir.size_in_bytes += sub_folder.size_in_bytes
    else
      sub_file = FileDefinition.new(file)
      curr_dir.size_in_bytes += sub_file.size_in_bytes
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
size = main_dir.size_in_bytes
puts("directory info:")
puts("path: #{main_dir.path}")
puts("size: #{get_size_string(size)} (#{size} B)")
puts("files: #{main_dir.file_list.length}")

#main_dir.file_list.each { |file|
#  puts("\t#{file.path} (#{file.get_size_string()})")
#}

#puts("json:")
puts("writing json to ./file_structure.json")
File.open("file_structure.json", 'w') {|f| f.write(main_dir.to_json()) }
#puts(main_dir.to_json())
