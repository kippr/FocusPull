module ListHelper

  def recently_completed_actions 
    completed_actions_for 3.days
  end

  def completed_actions_for period
    @focus.list.actions.completed_in_last( period ).sort_by( &:completed_date ).reverse
  end

  def age_histo_for status
    count_by_age = Hash[ @focus.list.with_status( status ).not.root.not.folders.group_by( &:age ).map{ |age, items| [age.to_i, items.size] } ]
    count_by_age.default = 0
    ( 1..( count_by_age.keys.max )).collect{ |n| count_by_age[n] }
  end

  def done_by_day_for period
    Focus::Graphable.sparkline_data_done( @focus.list ).to_a.slice( range_for( period ) )
  end

  def net_by_day_for period
    Focus::Graphable.sparkline_data( @focus.list ).to_a.slice( range_for( period ) )
  end

  # should go onto fixnum?
  def range_for period 
    (period / ( 60 * 60 * 24 ) * -1)..-1
  end

end
