
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
          puts "error: exception getting size for file #{path}" if @@options[:verbose]
          @bytes = 0
        end
      else
        @bytes = 0
      end
      
      unless reduced_scan # don't do this if we only want to know file sizes (for pseudofiles, .git folders, etc)
        begin 
          @ctime = File.ctime(path) 
        rescue
          puts "error getting creation time for file #{path}" if @@options[:verbose]
          @ctime = "unavailable"
        end
      
        begin 
          @mtime = File.ctime(path) 
        rescue
          puts "error getting modification time for file #{path}" if @@options[:verbose]
          @mtime = "unavailable"
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
        "bytes" => @bytes, 
        'ctime' => @ctime, 
        'mtime' => @mtime
      }
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
    
  end # FileDefinition
  
end # Fsinv