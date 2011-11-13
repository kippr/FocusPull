class HistoryController < ApplicationController
  
  attr_reader :max, :label
  
  def time_spent
    @top_level = Hash.new()
    folders = focus.children.select( &:is_folder? )
    folders.each{ | f | @top_level[ f ] = completed_count_by_week( f.list ) }

    period_filter = Focus::TemporalFilter.new( 7.days.ago.to_s, Date.today.to_s, :all_done )
    @weight_calculator = Focus::WeightCalculator.new( period_filter, [], [ :done ] )
    @weight_calculator.weigh( focus ) # todo: hack to deal with first run...
    @label = "Graph shows period since #{one_quarter_ago} ; Green shows average in area; Percentages are for #{period_filter.sublabel}"

    @all_folders = focus.list.folders.collect{ | f | [ f, completed_count_by_week( f.list ) ] }
    @top_level
  end
  
  private
    
    def completed_count_by_week nodes
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
