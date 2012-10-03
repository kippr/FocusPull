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
    verify_projects_that_should_not_be_active
    verify_projects_that_should_be_single_action
    @errors
  end

  def verify_projects_that_should_not_be_active
    active_projects = @focus.list.active.projects.select{ |p| /(Goals)|(Ideas)$/ =~ p.name }
    @errors[ :projects_that_should_not_be_active ] = active_projects unless active_projects.empty?
  end

  def verify_projects_that_should_be_single_action
    non_singletons = @focus.list.projects.not.single_action.select{ |p| /(Goals)|(Ideas)|(Actions)$/ =~ p.name }
    @errors[ :projects_that_should_be_single_action ] = non_singletons unless non_singletons.empty?
  end

end
