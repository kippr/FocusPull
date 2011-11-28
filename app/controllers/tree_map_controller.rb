class TreeMapController < ApplicationController

  def view
    @treemap = TreeMap.new( focus ).to_json
  end

end
