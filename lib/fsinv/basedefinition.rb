
module Fsinv

  class BaseDefinition
    
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
    
  end # FileDefinition
  
end # Fsinv