class HistoryController < ApplicationController
  
  attr_reader :max, :label
  
  def time_spent
    excluded_nodes = ( params[ "exclude" ] || "" ).split( "," ).collect(&:strip)
    @top_level = Hash.new()
    folders = focus.children.select( &:is_folder? ).reject{ | n | excluded_nodes.include? n.name }
    folders.each{ | f | @top_level[ f ] = completed_count_by_week( f.list ) }

    perc_period_start = ( params[ :from ] || 7.days.ago ).to_date
    perc_period_end = ( params[ :to ] || Date.today ).to_date
    
    perc_period_filter = Focus::TemporalFilter.new( perc_period_start.to_s, perc_period_end.to_s, :all_done )
    @weight_calculator = Focus::WeightCalculator.new( perc_period_filter, excluded_nodes, [ :done ] )
    @weight_calculator.weigh( focus ) # todo: hack to deal with first run...
    @label = "Percentages for period #{perc_period_filter.sublabel}; Graph shows period since #{one_quarter_ago} ; Green shows average spend for graphed period"

    @all_folders = focus.list.folders.reject{ | n | excluded_nodes.include? n.name }.collect{ | f | [ f, completed_count_by_week( f.list ) ] }
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
