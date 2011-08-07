module TimeSpentHelper
  
  def folder_sparks_tag( folders, max )
    return "" if folders.nil?
    group = ""
    folders.each do |folder, counts|
      group = folder.parent.name.gsub(/[^a-zA-Z0-9]/, '') if folder.depth <= 3
      haml_tag :span, { :class => "time-spent-detail #{group}" } do
        avg = counts.inject{ | a, b | a + b } / counts.count
        attrs = { :class=> "sparkline_completed", :sparkNormalRangeMax => avg, :sparkChartRangeMax => max }
        haml_tag :span, attrs do
          haml_concat counts.join( ',' )
        end
        haml_concat "&nbsp;" * (folder.depth * 3 - 6)
        haml_concat "#{folder.name} (#{'%2.2f' % @weight_calculator.percent_weight( folder )} %)"
      end
    end
  end
end
