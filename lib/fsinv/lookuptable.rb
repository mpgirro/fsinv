module Fsinv

  class LookupTable
  
    attr_accessor :val_map, :idcursor
  
    def initialize
      @val_map = Hash.new
      @idcursor = 0
    end  
  
    def contains?(value)
      return value == "" ? false : @val_map.has_value?(value)
    end
  
    def add(value)
      if self.contains?(value)
        return get_id(value)
      elsif value == ""
        return nil
      else
        @idcursor += 1
        @val_map[@idcursor] = value
        return @idcursor
      end
      
    end
    
    def empty?
      return @val_map.empty?
    end
  
    def get_id(value)
      return self.contains?(value) ? @val_map.key(value) : nil
    end
  
    def get_value(id)
      return self.contains?(value) ? @val_map[id] : nil
    end
  
    def to_a
      table_arr = []
      @val_map.each do | id, val | 
        table_arr << {"id" => id, "value" => val}
      end
      return table_arr
    end
  
    def as_json(options = { })
      return to_a
    end
  
    def to_json(*a)
      return as_json.to_json(*a)
    end
  
    def marshal_dump
      return {
        'val_map' => val_map, 
        'idcursor' => idcursor
      }
    end

    def marshal_load(data)
      self.val_map = data['val_map']
      self.idcursor = data['idcursor']
    end
  
  end # LookupTable

end