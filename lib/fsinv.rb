

# author: Maximilian Irro <max@disposia.org>, 2014

require 'pathname'

require 'fsinv/basedescription'
require 'fsinv/directorydescription'
require 'fsinv/filedescription'
require 'fsinv/inventory'
require 'fsinv/lookuptable'

begin
  require 'mime/types'
rescue LoadError
  puts "gem 'mime' required. Install it using 'gem install mime-types'"
  exit
end

unless /darwin/.match(RUBY_PLATFORM) # == osx
  begin
    require 'filemagic'
  rescue LoadError
    puts "gem 'filemagic' required. Install it using 'gem install ruby-filemagic'"
    puts "If you have trouble on OSX you may need to run 'brew install libmagic' before"
    exit
  end
end



module Fsinv
  
  # Kibibyte, Mebibyte, Gibibyte, etc... all the IEC sizes
  BYTES_IN_KiB = 2**10
  BYTES_IN_MiB = 2**20
  BYTES_IN_GiB = 2**30
  BYTES_IN_TiB = 2**40

  # these define a KB as 1000 bits, according to the SI prefix 
  BYTES_IN_KB = 10**3
  BYTES_IN_MB = 10**6
  BYTES_IN_GB = 10**9
  BYTES_IN_TB = 10**12

  IGNORE_FILES = ['.AppleDouble','.Parent','.DS_Store','Thumbs.db','__MACOSX','.wine']

  # calculate the sizes of these folders, yet do not write their content into the
  # inventory index. these appear as files on osx (.app, .bundle)
  PSEUDO_FILES = [
    '.app',
    '.bundle',
    '.mbox', # osx mailbox exports
    '.plugin',
    '.sparsebundle',
    '.abbu', # osx contact archive exports
    '.mode'  # SubEthaEdit and Coda modes
  ]
  
  class << self
    attr_accessor :options, :fmagic, :mime_tab, :magic_tab, :osx_tab, :fshugo_tab
  end
  
  Fsinv.options    = {}
  Fsinv.fmagic     = FileMagic.new unless /darwin/.match(RUBY_PLATFORM)
  Fsinv.magic_tab  = Fsinv::LookupTable.new
  Fsinv.mime_tab   = Fsinv::LookupTable.new
  Fsinv.osx_tab    = Fsinv::LookupTable.new
  Fsinv.fshugo_tab = Fsinv::LookupTable.new
  
  begin
    require 'ffi-xattr'
    Fsinv.options[:xattr] = true
  rescue LoadError
    puts "gem 'ffi-xattr' required. Install it using 'gem install ffi-xattr'"
    Fsinv.options[:xattr] = false
    #exit
  end
  
  module_function # all following methods will be callable from outside the module
  
  # tries to handle various encoding problems encounterd with path strings
  def sanitize_string(string)
    return string.encode("UTF-16BE", :invalid=>:replace, :undef => :replace, :replace=>"?")
                 .encode("UTF-8")
                 .gsub(/[\u0080-\u009F]/) {|x| x.getbyte(1).chr.force_encoding('windows-1252').encode('utf-8') }
                 .gsub(/\"/, "\\\"") # escape double quotes in string
  end

  def pretty_SI_bytes(bytes)
    return "%.1f TB" % (bytes.to_f / BYTES_IN_TB) if bytes > BYTES_IN_TB
    return "%.1f GB" % (bytes.to_f / BYTES_IN_GB) if bytes > BYTES_IN_GB
    return "%.1f MB" % (bytes.to_f / BYTES_IN_MB) if bytes > BYTES_IN_MB
    return "%.1f KB" % (bytes.to_f / BYTES_IN_KB) if bytes > BYTES_IN_KB
    return "#{bytes} B"
  end
  
  def pretty_IEC_bytes(bytes)
    return "%.1f TiB" % (bytes.to_f / BYTES_IN_TiB) if bytes > BYTES_IN_TiB
    return "%.1f GiB" % (bytes.to_f / BYTES_IN_GiB) if bytes > BYTES_IN_GiB
    return "%.1f MiB" % (bytes.to_f / BYTES_IN_MiB) if bytes > BYTES_IN_MiB
    return "%.1f KiB" % (bytes.to_f / BYTES_IN_KiB) if bytes > BYTES_IN_KiB
    return "#{bytes} B"
  end

  #returns DirectoryDefinition object
  def parse(folder_path, reduced_scan = false)
  
    if IGNORE_FILES.include?(File.basename(folder_path))
      # do nothing
    elsif File.basename(folder_path)[0..1] == "._"
      # these are some osx files no one cares about -> ignore
    elsif PSEUDO_FILES.include?(File.extname(folder_path)) # stuff like .app, .bundle, .mbox etc.
      puts "processing reduced_scan #{folder_path}" unless reduced_scan || Fsinv.options[:silent]
      reduced_scan = true
    elsif File.basename(folder_path)[0] == "."
      puts "processing dotfile #{folder_path}" unless reduced_scan || Fsinv.options[:silent]
      reduced_scan = true
    else
      puts "processing #{folder_path}/*" unless reduced_scan || Fsinv.options[:silent]
    end
  
    curr_dir = Fsinv::DirectoryDescription.new(folder_path, reduced_scan)
  
    #begin
      Pathname.new(folder_path).children.each { |f| 
        file = f.to_s.encode("UTF-8")
        if IGNORE_FILES.include?(File.basename(file))
          # do nothing
        elsif File.directory?(file) 
          sub_folder = parse(file, reduced_scan)
          curr_dir.bytes += sub_folder.bytes 
          curr_dir.file_list << sub_folder unless reduced_scan
          curr_dir.item_count += 1 # count this directory as an item
          curr_dir.item_count += sub_folder.item_count unless reduced_scan
        else
          puts "processing #{file}" if Fsinv.options[:verbose] && !reduced_scan && Fsinv.options[:silent].nil?
          sub_file = Fsinv::FileDescription.new(file, reduced_scan)
          curr_dir.bytes += sub_file.bytes 
          curr_dir.file_list << sub_file unless reduced_scan
          curr_dir.item_count += 1 unless reduced_scan
        end
      }
      #rescue
      #puts "permission denied: #{folder_path}" unless Fsinv.options[:silent]
      #end

    return curr_dir
  end # parse


  def filestructure_to_db(structitem)
    
    h = {
      :path => structitem.path,
      :bytes => structitem.bytes,
      :ctime => structitem.ctime,
      :mtime => structitem.mtime
    }
  
    case structitem
    when DirectoryDescription
      h[:entity_type] = "directory"
      h[:file_count] = structitem.file_count
      h[:item_count] = structitem.item_count
    when FileDescription
      h[:entity_type] = "file"
      
      mime_descr = Fsinv.mime_tab.get_value(structitem.mimetype)
      mime_id = MimeType.where(:mimetype => mime_descr).ids.first
      h[:mimetype] = mime_id
    
      magic_descr = Fsinv.magic_tab.get_value(structitem.magicdescr)
      magic_id = MagicDescription.where(:magicdescr => magic_descr).ids.first
      h[:magicdescr] = magic_id
    end
  
    osx_tags = [] # will be array of db ids
    unless structitem.osx_tags.nil?
      structitem.osx_tags.each do |json_id|
        tag = Fsinv.osx_tab.get_value(json_id)
        osx_tags << OsxTag.where(:tag => tag).ids.first
      end
    end
    h[:osx_tags] = osx_tags
  
    fshugo_tags = [] # will be array of db ids
    unless structitem.fshugo_tags.nil?
      structitem.fshugo_tags.each do |json_id|
        tag = Fsinv.fshugo_tab.get_value(json_id)
        fshugo_tags << FshugoTag.where(:tag => tag).ids.first
      end
    end
    h[:fshugo_tags] = fshugo_tags
  
    FileStructure.create(h)
  
    structitem.file_list.each { |child| filestructure_to_db(child) } if h[:entity_type] == "directory" 
  
  end


  def inventory_to_json(inventory)
    json_data = nil
    begin 
      require 'json'
      json_data = JSON.parse(inventory.to_json(max_nesting: 100))
      json_data = JSON.pretty_generate(json_data, :max_nesting => 100) 
    rescue LoadError
      puts "gem 'json' needed for JSON creation. Install using 'gem install json'"
    end
    return json_data
  end


  def filestructure_to_xml(xml, defobj)
    case defobj
    when DirectoryDescription
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
    when FileDescription
      xml.file{
        xml.path(defobj.path)
        xml.bytes(defobj.bytes)
        xml.mimetype(defobj.mimetype)
        xml.magicdescr(defobj.magicdescr)
      }
    end 
  end


  def inventory_to_xml(inventory)
    xml_data = nil
    begin
      require 'nokogiri'
      builder = Nokogiri::XML::Builder.new do |xml| 
        xml.inventory{
          #output the file structure
          xml.file_structure{
            inventory.file_structure.each do |fstruct|
              filestructure_to_xml(xml, fstruct)
            end
          } 
          #output the magic tab
          xml.magic_tab{
            inventory.magic_tab.val_map.each{ |id, val|
              xml.item{
                xml.id(id)
                xml.value(val)
          } } }
          #ouput the mime tab
          xml.mime_tab{
            inventory.mime_tab.val_map.each{ |id, val|
              xml.item{
                xml.id(id)
                xml.value(val)
          } } }
          
          xml.osx_tab{
            inventory.osx_tab.val_map.each{ |id, val|
              xml.item{
                xml.id(id)
                xml.value(val)
          } } }
          
          xml.fshugo_tab{
            inventory.fshugo_tab.val_map.each{ |id, val|
              xml.item{
                xml.id(id)
                xml.value(val)
          } } }
        }
      end
      xml_data = builder.to_xml
    rescue LoadError
      puts "gem 'nokogiri' needed for XML creation. Install using 'gem install nokogiri'"
    end
    return xml_data
  end


  def inventory_to_yaml(inventory)
    yml_data = nil
    begin
      require 'yaml'  
      yml_data = YAML::dump(inventory)
    rescue LoadError
      puts "gem 'yaml' needed for YAML creation. Install using 'gem install yaml'"
    end
    return yml_data
  end
end # Fsinv



