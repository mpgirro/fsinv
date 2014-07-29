
require 'fsinv'

module Fsinv

  class FileDescription < Fsinv::BaseDescription
    
    include Fsinv
  
    attr_accessor :mimetype,:magicdescr,:crc32,:md5
  
    def initialize(path, reduced_scan = false)

      super(path,reduced_scan)

      unless reduced_scan # don't do this if we only want to know file sizes (for pseudofiles, .git folders, etc)
        @mimetype = get_mime_id
        @magicdescr = get_magic_descr_ids
        @crc32 = calc_crc32
        @md5 = calc_md5
      end
    end # initialize
  
    def to_hash
      h = super.to_hash
      h["type"] = "file"
      h["mimetype"] = @mimetype unless @mimetype.nil?
      h["magicdescr"] = @magicdescr unless @magicdescr.nil?
      h["crc32"] = @crc32 unless @crc32.nil?
      h["md5"] = @md5 unless @md5.nil?
      return h
    end # to_hash
  
    def as_json(options = { })
      return to_hash
    end
    
    def to_json(*a)
      return as_json.to_json(*a )
    end
  
    def marshal_dump
      h = self.to_json
      h.delete("type")
      return h
    end

    def marshal_load(data)
      self.path = data['path']
      self.bytes = data['bytes']
      self.ctime = data['ctime'] if data['ctime'].exists?
      self.mtime = data['mtime'] if data['mtime'].exists?
      self.mimetype = data['mimetype'] if data['mimetype'].exists?
      self.magicdescr = data['magicdescr'] if data['magicdescr'].exists?
      self.crc32 = data["crc32"] if data['crc32'].exists?
      self.md5 = data["md5"] if data['md5'].exists?
      self.osx_tags = data['osx_tags'] if data['osx_tags'].exists?
      self.fshugo_tags = data['fshugo_tags'] if data['fshugo_tags'].exists?
    end
    
    private
    def get_mime_id
      begin
        type_str = MIME::Types.type_for(@path).join(', ')
        @@mime_tab.add(type_str) unless @@mime_tab.contains?(type_str)
        return @@mime_tab.get_id(type_str)
      rescue ArgumentError # if this happens you should definitly repair some file names
        puts "error: mime type unavailable" unless @@options[:silent]
        return nil
      end
    end
    
    private
    def get_magic_descr_ids
      begin 
        description = sanitize_string(@@fmagic.file(@path))
        @@magic_tab.add(description) unless @@magic_tab.contains?(description)
        return @@magic_tab.get_id(description)
      rescue
        puts "error: file magic file information unavailable" unless @@options[:silent]
        return nil
      end
    end
    
    private 
    def calc_crc32
      if @@options[:crc32]
        begin
          return Digest::CRC32.file(@path).hexdigest
        rescue
          puts "error calculating crc32 for #{path}" if @@options[:verbose]
          return nil
        end
      end
    end
    
    
    private 
    def calc_md5
      if @@options[:md5]
        begin
          return Digest::MD5.file(@path).hexdigest
        rescue
          puts "error calculating md5 for #{path}" if @@options[:verbose]
          return nil
        end
      end
    end
    
  end # FileDefinition
end