class HistoryController < ApplicationController
  
  def time_spent
    @top_level = focus.children
    @done = { Date.today.cweek => 10, Date.today.cweek - 1 => 8, Date.today.cweek - 2 => 12 }
  end
  
end