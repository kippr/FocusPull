class MetaController < ApplicationController

  def verify_rules
    @errors = GtdRules.new( focus ).verify.tap{ |j| pp j }
  end

end

class GtdRules

  def initialize focus
    @focus = focus
    @errors = {}
  end

  def verify
    verify_idea_projects
    @errors
  end

  def verify_idea_projects
    active_idea_projects = @focus.list.active.projects.select{ |p| /Ideas$/ =~ p.name }
    @errors[ :active_idea_project ] = active_idea_projects unless active_idea_projects.empty?
  end

end
