module Focus
# todo: this class in need of serious TLC
class Graphable
  
  def self.histo focus
    Graphable.new( focus, HistoVisitor.new ).results
  end

  def self.trend focus
    visitor = TrendVisitor.new( earliest focus )
    Graphable.new( focus, visitor ).results
  end
  
  def self.sparkline_data focus
    visitor = SparklineVisitor.new( earliest focus )
    Graphable.new( focus, visitor ).results
  end
  
  def initialize focus, visitor
    @focus = focus
    @visitor = visitor
  end
  
  def results
    @focus.list.each{ | item | @visitor.accept item }
    @visitor
  end
  
  private
    def self.earliest focus
      focus.list.min { | a,b | a.created_date <=> b.created_date }.created_date
    end
    
end

# todo: use this for meta map items by status collection?
# todo: this thing is doing double duty as visitor & results :(
class HistoVisitor
  include VisitorMixin, Enumerable
  
  attr_reader :done_projects, :done_actions, :open_projects, :active_actions
  
  def initialize
    @done_actions = Results.new
    @done_projects = Results.new
    @active_actions = Results.new
    @open_projects = Results.new
  end
   
  def visit_project project
      (project.done? ? @done_projects : @open_projects).add project.age, project
  end

  def visit_action action
      (action.done? ? @done_actions : @active_actions).add action.age, action
  end
  
  def size
    [@done_actions, @done_projects, @active_actions, @open_projects].max {|a,b| a.size <=> b.size }.size
  end

  def each( &block )
    yield "Day, Open projects, Done projects, Active actions, Done actions" 
    (1...size).each do | i |
      yield "#{i}, #{open_projects[i].size}, #{done_projects[i].size}, #{active_actions[i].size}, #{done_actions[i].size}"
    end
  end

end

# todo: loads of dupe with above
class TrendVisitor
  include VisitorMixin, Enumerable

  attr_reader :added_projects, :added_actions, :completed_projects, :completed_actions
  
  def initialize( earliest_date )
    @added_projects = Results.new
    @added_actions = Results.new
    @completed_projects = Results.new
    @completed_actions = Results.new
    @earliest = earliest_date
  end
   
  def visit_project project
    @added_projects.add( project.created_date - @earliest, project )
    @completed_projects.add( project.completed_date - @earliest, project ) if project.done?
  end

  def visit_action action
    @added_actions.add( action.created_date - @earliest, action )
    @completed_actions.add( action.completed_date - @earliest, action ) if action.done?
  end
  
  def size
    [@added_projects, @added_actions, @completed_projects, @completed_actions].max {|a,b| a.size <=> b.size }.size
  end
  
  def each( &block )
    yield "Day, Added projects, Completed projects, Added actions, Completed actions" 
    (0...size).each do | i |
      yield "#{@earliest + i}, #{added_projects[i].size}, #{completed_projects[i].size}, #{added_actions[i].size}, #{completed_actions[i].size}"
    end
  end 
  
end

class SparklineVisitor < TrendVisitor
  
  def each
    (0...size).each do | i |
      yield added_actions[i].size + added_projects[i].size * 3 - completed_actions[i].size - completed_projects[i].size * 3
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
end