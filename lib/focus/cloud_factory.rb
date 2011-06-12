require 'cloud'

module Focus
class CloudFactory
  
  def self.create_cloud focus, output_path
    self.new_cloud( focus, output_path ).dump_pdf
  end

  def self.create_cloud_pdf focus, output_path
    self.new_cloud( focus, output_path ).pdf
  end
  
  private 
    def self.new_cloud( focus, output_path )
      factory = CloudFactory.new focus, output_path
      factory.create_input_file
      factory.create_cloud      
    end
  
  def initialize focus, output_path
    @focus, @output_path = focus, output_path
  end
  
  #todo: is there a package private type thing available?
  public
  def create_input_file
    @input_file = "#{@output_path}/focus_words.txt"
    for_weight = Weight.new
    File.open(@input_file , "w") do |f| 
      @focus.each do |node| 
        for_weight.of node  do 
          node.name.split(" ").each do |s| 
            f.puts( s ) if s.length > 2
          end
        end
      end
    end
  end
  
  def create_cloud
    temp = PaperSizes.new
    @paper_sizes = temp.paper_sizes
    @ordered_sizes = temp.ordered_sizes
    options = {:file => @input_file,
               :min_font_size => 12,
               :max_words => 180,
               :font => "Times-Roman",
               :palette => "heat",
               :lang => "EN",
               :distance_type => "ellipse",
               :short_name => "#{@output_path}/focus-cloud"          
    }
    @cloud = WordCloud.new(options)
    @cloud.place_boxes("mostly-horizontal")
    @cloud.put_placed_boxes_in_pdf
    @cloud
  end
  
end

class Weight
  include VisitorMixin
  
  def of node
    node.visit(self).times{ yield }
  end
  
  def visit_default item
    0
  end
  
  def visit_folder item
    3
  end

  def visit_project item
    item.single_actions? ? 0 : 3
  end
  
  def visit_action item
    1
  end
  
end
end