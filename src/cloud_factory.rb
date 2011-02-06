require 'cloud'
require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/archive_parser')
require File.join(File.dirname(__FILE__), '../src/mindmap_factory')
require 'nokogiri'

class CloudFactory
  
  def self.create_cloud focus, output_path
    factory = CloudFactory.new focus, output_path
    factory.create_input_file
    factory.create_cloud
    factory.write_pdf
  end
  
  def initialize focus, output_path
    @focus, @output_path = focus, output_path
  end
  
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
               :max_words => 300,
               :font => "Times-Roman",
               :palette => "heat",
               :lang => "EN",
               :distance_type => "ellipse",
               :short_name => "#{@output_path}/focus-cloud"          
    }
    @cloud = WordCloud.new(options)
    @cloud.place_boxes("mostly-horizontal")
    @cloud.put_placed_boxes_in_pdf
  end
  
  def write_pdf
    @cloud.dump_pdf
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
    2
  end
  
  def visit_action item
    1
  end
  
end
