class HistoryController < ApplicationController
  
  def time_spent
    @top_level = focus.children.select( &:is_folder? ).inject( Hash.new ) do | t, i |
      grouped_by_week = i.list.completed.group_by{ | i | i.completed_date.cwyear_and_week }
      grouped_by_week.default = []
      counts = []
      one_quarter_ago.step( Date.today, 7) do | week |
        count = grouped_by_week[ week.cwyear_and_week ].inject( 0 ){ | t, i | t + i.weight }
        @max = [ @max || 0, count ].max
        counts << count
      end
      t[ i.name ] = counts
      t
    end
  end
  
  private
    def one_quarter_ago
      13.weeks.ago.to_date
    end
  
end