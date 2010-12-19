class Focus
  
  def initialize( )
    @projects = Hash.new
  end
  
  #todo: this won't handle 2 projects with same name!
  def projects=( projects )
    projects.each { | p | @projects[ p.name ] = p }
  end
  
  def project_list
    @projects.keys
  end
  
  def project( name )
    @projects[ name ]
  end
  
end

class Project
  
  attr_reader :name
  
  def initialize( name )
    @name = name
  end

end