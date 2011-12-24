
class TreeMapController < ApplicationController

  def view
    #todo: make Personal exclusion site wide
    #todo: add a 'filtered' focus for tree traversal, just like focus.list!
    @active_treemap = time( "Active map" ) { TreeMap.active( focus, *focus_config.exclusions ).to_json }
    @remaining_treemap = time( "Remaining map" ) { TreeMap.remaining( focus, *focus_config.exclusions ).to_json }
    @recently_completed_treemap = time( "Recent map" ) { TreeMap.recent( focus, focus_config.period_start, *focus_config.exclusions ).to_json }
    @treemap = true
  end

end
