class Focus
  
  def initialize( )
    @projects = Hash.new
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
  
end

class Project
  
  attr_reader :name
  attr_accessor :status
  
  def initialize( name )
    @name = name
    @status = "active"
  end
  
  def to_s
    "#{@name} [#{@status}]" 
  end
  
end