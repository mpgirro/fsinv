
require 'fsinv'

module Fsinv

  class DirectoryDescription < Fsinv::BaseDescription
    
    include Fsinv
  
    attr_accessor :file_count,:item_count,:file_list
    
    def initialize(path, reduced_scan = false)
      
      super(path,reduced_scan)
      
      @file_list = []
      @file_count = 0 
      @item_count = 0
    end # initialize
    
    def to_hash
      h = super.to_hash
      h["type"] = "directory"
      h["file_count"] = @file_count
      h["item_count"] = @item_count
      h["file_list"] = @file_list
      return h
    end # to_hash
  
    def as_json(options = { })
      return to_hash
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