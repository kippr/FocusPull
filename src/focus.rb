class Focus
  
  attr_reader :root
  
  def initialize( root )
    @projects = Hash.new
    @root = root
  end
  
  #todo: this won't handle 2 projects with same name!
  def add_project( p )
    @projects[ p.name ] = p
  end
      
  def project_list
    @projects.values
  end
  
  def project( name )
    @projects[ name ]
  end
  
  alias add_folder add_project
  alias folder project
  alias folder_list project_list
  
end

class Item
  attr_reader :name
  attr_accessor :parent
  attr_reader :children
  
  def initialize( name )
    @name = name
    @children = []
  end
  
  def to_s
    "#{self.class}: #{@name} <- #{self.parent}" 
  end
end


class Folder < Item
  def to_s
    super + " "
  end

end

class Project < Item
  
  attr_accessor :status
  
  def initialize( name )
    super( name )
    @status = "active"
  end
  
  def to_s
    super + " [#{@status}]" 
  end
  
end