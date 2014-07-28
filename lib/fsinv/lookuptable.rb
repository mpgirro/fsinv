module Fsinv

  class LookupTable
  
    attr_accessor :val_map, :idcursor
  
    def initialize
      @val_map = Hash.new
      @idcursor = 1
    end  
  
    def contains?(descr)
      return descr == "" ? false : @val_map.has_value?(descr)
    end
  
    def add(descr)
      unless descr == ""
        @val_map[idcursor] = descr
        @idcursor += 1
      end
    end
    
    def empty?
      return @val_map.empty?
    end
  
    def get_id(descr)
      return descr == "" ? 0 : @val_map.key(descr)
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