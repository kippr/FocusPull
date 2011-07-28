module TimeSpentHelper
  
  def folder_sparks_tag( folders, max )
    return "" if folders.nil?
    folders.each do |node, counts|
      indent( node.depth ) do
        haml_tag :li do
          attributes = {}
          avg = counts.inject{ | a, b | a + b } / counts.count
          attrs = { :class=> "sparkline_completed", :sparkNormalRangeMax => avg, :sparkChartRangeMax => max }
          haml_tag :span, attrs do
            haml_concat counts.join( ',' )
          end
          haml_concat node.name
        end
      end
    end
  end
  
  private
    def indent( level, &block )
      if level > 1
        haml_tag :ul do
          indent( level - 1, &block )
        end
      else
        yield
      end
    end
  
end