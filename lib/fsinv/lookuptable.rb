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
      else
        unless value == ""
          @idcursor += 1
          @val_map[@idcursor] = value
          return @idcursor
        else 
          return 0
        end
      end
      
    end
    
    def empty?
      return @val_map.empty?
    end
  
    def get_id(value)
      return value == "" ? 0 : @val_map.key(value)
    end
  
    def get_value(id)
      return @val_map[id]
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