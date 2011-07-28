class HistoryController < ApplicationController
  
  attr_reader :max
  
  def time_spent
    @top_level = Hash.new()
    folders = focus.children.select( &:is_folder? )
    folders.each{ | f | @top_level[ f.name ] = count_by_week( f.list ) }
    @top_level
  end
  
  private
    
    def count_by_week nodes
      completed_by_week = nodes.completed.group_by{ | i | i.completed_date.cwyear_and_week }
      completed_by_week.default = []
      counts = []
      one_quarter_ago.step( Date.today, 7) do | week |
        count = completed_by_week[ week.cwyear_and_week ].inject( 0 ){ | t, i | t + i.weight }
        counts << count
      end
      @max = counts.max if counts.max > ( @max || 0 )
      counts
    end
  
    def one_quarter_ago
      13.weeks.ago.to_date
    end
end