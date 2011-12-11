class TreeMapController < ApplicationController

  def view
    @active_treemap = TreeMap.active( focus ).to_json
    @remaining_treemap = TreeMap.remaining( focus ).to_json
    @recently_completed_treemap = TreeMap.recent( focus ).to_json
    @treemap = true
  end

end
