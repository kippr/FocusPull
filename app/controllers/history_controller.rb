class HistoryController < ApplicationController
  
  def time_spent
    @done = 
      { Date.today.cweek => 8, Date.today.cweek - 2=> 12, Date.today.cweek - 3 => 10, Date.today.cweek - 4 => 10, Date.today.cweek - 5 => 2, Date.today.cweek - 6 => 12, Date.today.cweek - 7 => 11, Date.today.cweek - 8 => 15 }
    @top_level = focus.children.group_by{ |c| c.name }
  end
  
end