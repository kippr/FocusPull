class TreeMapController < ApplicationController

  def view
    @active_treemap = TreeMap.new( focus ).to_json
    @remaining_treemap = TreeMap.new( focus, :remaining? ).to_json
    @treemap = true
  end

end
