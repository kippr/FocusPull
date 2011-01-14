require File.join(File.dirname(__FILE__), '../src/focus')

# todo: this class in need of serious TLC
class Graphable
  
  def self.histo focus
    Graphable.new( focus, HistoVisitor.new ).results
  end

  def self.trend focus
    earliest = focus.min { | a,b | a.created_date <=> b.created_date }
    visitor = TrendVisitor.new( earliest.created_date )
    Graphable.new( focus, visitor ).results
  end
  
  def initialize focus, visitor
    @focus = focus
    @visitor = visitor
  end
  
  def results
    @focus.each{ | item | @visitor.accept item }
    @visitor
  end
    
end

# todo: use this for meta map items by status collection?
# todo: this thing is doing double duty as visitor & results :(
class HistoVisitor
  include VisitorMixin, Enumerable
  
  attr_reader :done_projects, :done_tasks, :open_projects, :active_tasks
  
  def initialize
    @done_tasks = Results.new
    @done_projects = Results.new
    @active_tasks = Results.new
    @open_projects = Results.new
  end
   
  def visit_project project
      (project.done? ? @done_projects : @open_projects).add project.age, project
  end

  def visit_task task
      (task.done? ? @done_tasks : @active_tasks).add task.age, task
  end
  
  def size
    [@done_tasks, @done_projects, @active_tasks, @open_projects].max {|a,b| a.size <=> b.size }.size
  end

  def each( &block )
    yield "Day, Open projects, Done projects, Active tasks, Done tasks" 
    (1...size).each do | i |
      yield "#{i}, #{open_projects[i].size}, #{done_projects[i].size}, #{active_tasks[i].size}, #{done_tasks[i].size}"
    end
  end

end

# todo: loads of dupe with above
class TrendVisitor
  include VisitorMixin, Enumerable

  attr_reader :added_projects, :added_tasks, :completed_projects, :completed_tasks
  
  def initialize( earliest_date )
    @added_projects = Results.new
    @added_tasks = Results.new
    @completed_projects = Results.new
    @completed_tasks = Results.new
    @earliest = earliest_date
  end
   
  def visit_project project
    @added_projects.add( project.created_date - @earliest, project )
    @completed_projects.add( project.completed_date - @earliest, project ) if project.done?
  end

  def visit_task task
    @added_tasks.add( task.created_date - @earliest, task )
    @completed_tasks.add( task.completed_date - @earliest, task ) if task.done?
  end
  
  def size
    [@added_projects, @added_tasks, @completed_projects, @completed_tasks].max {|a,b| a.size <=> b.size }.size
  end
  
  def each( &block )
    yield "Day, Added projects, Completed projects, Added actions, Completed actions" 
    (0...size).each do | i |
      yield "#{@earliest + i}, #{added_projects[i].size}, #{completed_projects[i].size}, #{added_tasks[i].size}, #{completed_tasks[i].size}"
    end
  end 
  
end

# bit dodgy extending array, but we'll see how we go
class Results < Array
  
  
  def add key, item
    self.[]( key ) << item
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