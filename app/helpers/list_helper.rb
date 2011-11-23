module ListHelper
  def recently_completed_actions 
    @focus.list.actions.completed_in_last( 3.days ).sort_by( &:completed_date ).reverse
  end
end
