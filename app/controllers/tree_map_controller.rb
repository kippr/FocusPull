
class TreeMapController < ApplicationController

  def view
    #todo: make Personal exclusion site wide
    #todo: add a 'filtered' focus for tree traversal, just like focus.list!
    @active_treemap = TreeMap.active( focus, *focus_config.exclusions ).to_json
    @remaining_treemap = TreeMap.remaining( focus, *focus_config.exclusions ).to_json
    @recently_completed_treemap = TreeMap.recent( focus, *focus_config.exclusions ).to_json
    @treemap = true
  end

end
