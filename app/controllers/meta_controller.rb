class MetaController < ApplicationController

  def verify_rules
    GtdRules.new( focus ).verify
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
    active_idea_projects = @focus.list.active.projects.select{ |p| /[Ii]deas$/ =~ p.name }
    @errors[ :active_idea_project ] = active_idea_projects if active_idea_projects
  end

end
