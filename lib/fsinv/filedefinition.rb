module Fsinv

  class FileDefinition
    
    include Fsinv
  
    attr_accessor :path,:bytes,:ctime,:mtime,:mimetype,:magicdescr,:crc32,:md5,:osx_tags,:fshugo_tags
  
    def initialize(path, reduced_scan = false)
      @path = path
      @bytes = File.size(@path) rescue (puts "error: exception getting size for file #{path}" if @options[:verbose]; 0)
    
      unless reduced_scan # don't do this if we only want to know file sizes (for pseudofiles, .git folders, etc)
      
        begin 
          @ctime = File.ctime(path) 
        rescue
          puts "error getting creation time for file #{path}" if @options[:verbose]
          @ctime = "unavailable"
        end
      
        begin 
          @mtime = File.ctime(path) 
        rescue
          puts "error getting modification time for file #{path}" if @options[:verbose]
          @mtime = "unavailable"
        end

        begin
          type_str = MIME::Types.type_for(@path).join(', ')
          @mime_tab.add(type_str) unless @mime_tab.contains?(type_str)
          @mimetype = @mime_tab.get_id(type_str)
        rescue ArgumentError # if this happens you should definitly repair some file names
          @mimetype = nil
        end
    
        begin 
          description = sanitize_string(@fmagic.file(@path))
          @magic_tab.add(description) unless @magic_tab.contains?(description)
          @magicdescr = @magic_tab.get_id(description)
        rescue
          puts "error: file kind information unavailable" unless @options[:silent]
          @magicdescr = nil
        end
      
        if @options[:crc32]
          begin
            @crc32 = Digest::CRC32.file(@path).hexdigest
          rescue
            puts "error calculating crc32 for #{path}" if @options[:verbose]
            @crc32 = "error during calculation"
          end
        end

        if @options[:md5]
          begin
            @crc32 = Digest::MD5.file(@path).hexdigest
          rescue
            puts "error calculating md5 for #{path}" if @options[:verbose]
            @crc32 = "error during calculation"
          end
        end
      
        @osx_tags = osx_tag_ids(path) if /darwin/.match(RUBY_PLATFORM) # == osx
        @fshugo_tags = fshugo_tag_ids(path)
      else
        @mimetype = nil
        @magicdescr = nil
        @osx_tags = []
        @fshugo_tags = []
      end
    end # initialize
  
    def to_hash
      p = sanitize_string(@path) rescue "path encoding broken" # there can be ArgumentError and UndefinedConversionError
      h = {
        "type" => "file",
        "path" => p,
        "bytes" => @bytes, 
        'ctime' => @ctime, 
        'mtime' => @mtime
      }
      h["mimetype"] = @mimetype unless @mimetype.nil?
      h["magicdescr"] = @magicdescr unless @magicdescr.nil?
      h["crc32"] = @crc32 unless @crc32.nil?
      h["md5"] = @md5 unless @md5.nil?
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
      self.mimetype = data['mimetype']
      self.magicdescr = data['magicdescr']
      self.crc32 = data["crc32"] if data['crc32'].exists?
      self.md5 = data["md5"] if data['md5'].exists?
      self.osx_tags = data['osx_tags'] if data['osx_tags'].exists?
      self.fshugo_tags = data['fshugo_tags'] if data['fshugo_tags'].exists?
    end
  end # FileDefinition
end