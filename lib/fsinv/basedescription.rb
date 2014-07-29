
require 'fsinv'

module Fsinv

  class BaseDescription
    
    include Fsinv
    
    attr_accessor :path,:bytes,:ctime,:mtime,:osx_tags,:fshugo_tags
    
    def initialize(path, reduced_scan = false)
      @path = path
      
      unless File.directory?(path)
        begin 
          @bytes = File.size(@path) 
        rescue 
          puts "error: exception getting size for file #{path}" if Fsinv.options[:verbose]
          @bytes = 0
        end
      else
        @bytes = 0
      end
      
      unless reduced_scan # don't do this if we only want to know file sizes (for pseudofiles, .git folders, etc)
        begin 
          @ctime = File.ctime(path) 
        rescue
          puts "error getting creation time for file #{path}" if Fsinv.options[:verbose]
          @ctime = nil
        end
      
        begin 
          @mtime = File.ctime(path) 
        rescue
          puts "error getting modification time for file #{path}" if Fsinv.options[:verbose]
          @mtime = nil
        end
        
        @osx_tags = osx_tag_ids(path) if /darwin/.match(RUBY_PLATFORM) # == osx
        @fshugo_tags = fshugo_tag_ids(path)
      else
        @osx_tags = []
        @fshugo_tags = []
      end
    end # initialize
    
    def to_hash
      p = sanitize_string(@path) rescue "path encoding broken" # there can be ArgumentError and UndefinedConversionError
      h = {
        "path" => p,
        "bytes" => @bytes
      }
      h['ctime'] = @ctime unless @ctime.nil?
      h['mtime'] = @mtime unless @mtime.nil?
      h["osx_tags"] = @osx_tags unless @osx_tags.empty?
      h["fshugo_tags"] = @fshugo_tags unless @fshugo_tags.empty?
      return h
    end # to_hash
  
    def as_json(options = { })
      return to_hash
    end
    
    def to_json(*a)
      return as_json.to_json(*a )
    end
    
    def osx_tag_ids(file_path)
      # array with the kMDItemUserTags strings 
      # of the extended file attributes of 'path'
      tags = %x{mdls -name 'kMDItemUserTags' -raw "#{file_path}"|tr -d "()\n"}.split(',').map { |tag| 
        tag.strip.gsub(/"(.*?)"/,"\\1")
      }
      # if there are now tags, mdls returns "null" -> we don't want this
      if tags.length == 1 && tags[0] == "null"
        return []
      else
        tag_ids = []
        tags.each do |tag|
          @@osx_tab.add(tag) unless @@osx_tab.contains?(tag)
          tag_ids << @@osx_tab.get_id(tag)
        end
        return tag_ids
      end
    end # osx_tag_ids


    def fshugo_tag_ids(file_path)
      xattr = Xattr.new(file_path)
      unless xattr["fshugo"].nil?
        tags = xattr["fshugo"].split(";") 
        tag_ids = []
        tags.each do |tag|
          @@fshugo_tab.add(tag) unless @@fshugo_tab.contains?(tag)
          tag_ids << @@fshugo_tab.get_id(tag)
        end
        return tag_ids
        #return tags
      else
        return []
      end 
    end # fshugo_tag_ids
    
  end # FileDefinition
  
end # Fsinv