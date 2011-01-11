require File.join(File.dirname(__FILE__), '../src/focus')

class Graphable
  include Enumerable
  
  def self.histo focus
    Graphable.new( focus )
  end
  
  def initialize focus
    @focus = focus
  end
  
  def results
    visitor = HistoVisitor.new
    @focus.each{ | item | visitor.accept item }
    visitor
  end
  
  def each( &block )
    r = results
    yield "Day, Open projects, Done projects, Active tasks, Done tasks" 
    (1...r.size).each do | i |
      yield "#{i}, #{r.open_projects[i].size}, #{r.done_projects[i].size}, #{r.active_tasks[i].size}, #{r.done_tasks[i].size}"
    end
  end
  
end

# todo: use this for meta map items by status collection?
class HistoVisitor
  include VisitorMixin
  
  attr_reader :done_projects, :done_tasks, :open_projects, :active_tasks
  
  def initialize
    @done_tasks = Results.new
    @done_projects = Results.new
    @active_tasks = Results.new
    @open_projects = Results.new
  end
   
  def visit_project project
      (project.done? ? @done_projects : @open_projects).add project
  end

  def visit_task task
      (task.done? ? @done_tasks : @active_tasks).add task
  end
  
  def size
    [@done_tasks, @done_projects, @active_tasks, @open_projects].max {|a,b| a.size <=> b.size }.size
  end

end

# bit dodgy extending array, but we'll see how we go
class Results < Array
  
  def add item
    self.[]( item.age ) << item
  end
    
    
  def []( index )
    value = self.fetch( index, nil )
    if value.nil?
      value = []
      self[ index ] = value
    end
    value
  end
  
end