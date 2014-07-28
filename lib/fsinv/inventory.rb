
require 'fsinv'

module Fsinv

  class Inventory
    
    include Fsinv
  
    attr_accessor :file_structure, :timestamp, :magic_tab, :mime_tab, :osx_tab, :fshugo_tab
  
    def initialize(file_structure)
      @file_structure = file_structure
      @timestamp  = Time.now
      @magic_tab  = @@magic_tab
      @mime_tab   = @@mime_tab
      @osx_tab    = @@osx_tab
      @fshugo_tab = @@fshugo_tab
    end 
  
    def size
      size = 0
      file_structure.each do |fs|
        size += fs.bytes
      end
      return size
    end
  
    def item_count
      count = 0
      file_structure.each do |fs|
        count += fs.item_count
      end
      return count
    end
  
    def to_hash
      h = {
        "timestamp" => @timestamp,
        "file_structure" => @file_structure,
      }
      h["mime_tab"] = @mime_tab unless @mime_tab.empty?
      h["magic_tab"] = @magic_tab unless @magic_tab.empty?
      h["osx_tab"] = @osx_tab unless @osx_tab.empty?
      h["fshugo_tab"] = @fshugo_tab unless @fshugo_tab.empty?
      return h
    end
  
    def as_json(options = { })
      return to_hash
    end
  
    def to_json(*a)
      as_json.to_json(*a)
    end
  
    def marshal_dump
      return to_hash
    end

    def marshal_load(data)
      self.file_structure = data['file_structure'] if data['file_structure'].exists?
      self.timestamp = data['timestamp'] if data['timestamp'].exists?
      self.magic_tab = data['magic_tab'] if data['magic_tab'].exists?
      self.mime_tab = data['mime_tab'] if data['mime_tab'].exists?
      self.osx_tab = data['osx_tab'] if data['osx_tab'].exists?
      self.fshugo_tab = data['fshugo_tab'] if data['fshugo_tab'].exists?
    end
    
  end
  
end