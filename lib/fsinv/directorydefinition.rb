module Fsinv

  class DirectoryDefinition
    
    include Fsinv
  
    attr_accessor :path,:bytes,:ctime,:mtime,:file_count,:item_count,:osx_tags,:fshugo_tags,:file_list
    
    def initialize(path, reduced_scan = false)
      @path = path
      @bytes = 0
      @file_list = []
      @file_count = 0 
      @item_count = 0
      unless reduced_scan # don't do this if we only want to know file sizes (for pseudofiles, .git folders, etc)
        @ctime = File.ctime(path) rescue (puts "error getting creation time for directory #{path}" if @options[:verbose]; "unavailable" )
        @mtime = File.mtime(path) rescue (puts "error getting modification time for directory #{path}" if @options[:verbose]; "unavailable" )
        @osx_tags = osx_tag_ids(path) if /darwin/.match(RUBY_PLATFORM) # == osx
        @fshugo_tags = fshugo_tag_ids(path)
      end
    end # initialize
  
    def as_json(options = { })
      p = sanitize_string(@path) rescue "path encoding broken" # there can be ArgumentError and UndefinedConversionError
      h = {
        "type" => "directory", 
        "path" => p, 
        "bytes" => bytes, 
        'ctime' => @ctime, 
        'mtime' => @mtime, 
        "file_count" => @file_count, 
        "item_count" => @item_count
      }
      h["osx_tags"] = @osx_tags #unless @osx_tags.empty?
      h["fshugo_tags"] = @fshugo_tags #unless @fshugo_tags.empty?
      h["file_list"] = @file_list
      return h
    end
  
    def to_json(*a)
      return as_json.to_json(*a)
    end
  
    def marshal_dump
      h = self.to_json
      h.delete("type")
      return h
    
    end

    def marshal_load(data)
      self.path = data['path']
      self.bytes = data['bytes']
      self.ctime = data['ctime']
      self.mtime = data['mtime']
      self.file_count = data['file_count']
      self.item_count = data['item_count']
      self.osx_tags = data['osx_tags'] if data['osx_tags'].exists?
      self.fshugo_tags = data['fshugo_tags'] if data['fshugo_tags'].exists?
      self.file_list = data['file_list']
    end
    
  end # DirectoryDefinition

end