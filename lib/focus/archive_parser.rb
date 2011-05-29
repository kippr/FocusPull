
module Focus
  
  class FocusParser

  def initialize( directory, filename, username )
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
    
    @directory = directory
    @filename = filename
    @username = username
  end

  def parse
    root = Focus.new
    @ref_to_node = Hash.new
    @ref_to_node[ nil ] = root
    @parent_ref_of = Hash.new
    
    foreach_archive_xml do | content |
      @xml = Nokogiri::XML( content )
      parse_actions
      parse_folders
    end
    
    resolve_links
    root
  end

  private
  
    def parse_actions
      for_sorted( "task" ).each do | action_node |
        @log.debug( "Processing action: #{action_node}")
        project_node = action_node.at_xpath( './xmlns:project' )
        if project_node
          item = create_node( action_node, Project )
          item.status = xpath_content( project_node, './xmlns:status', nil)
          item.set_single_actions if project_node.at_xpath( './xmlns:singleton' )                    
        else
          item = create_node( action_node, Action )
        end
        item.completed( xpath_content( action_node, './xmlns:completed', nil ) )        
      end
    end
        
    def parse_folders
      for_sorted( 'folder' ).each do | folder_node |
        @log.debug( "Processing folder: #{folder_node}" )
        create_node( folder_node, Folder )
      end
    end
    
    def create_node( node, type )
      name = xpath_content( node, './xmlns:name' )
      item = type.new( name )
      item.created_date = xpath_content( node, './xmlns:added', nil )
      item.updated_date = xpath_content( node, './xmlns:modified', nil )
      track_links( item, node )
      item        
    end
    
    def resolve_links
      @log.debug( "Resolving links for #{@ref_to_node}")
      @ref_to_node.each_pair do | ref, node |
        # replace the string key ref we stored on each node with the actual parent
        node.link_parent( @ref_to_node[ @parent_ref_of[ node ] ] )
      end
    end
    
    def track_links( item, item_node )
      # parent id is held as idref
      parent_id = xpath_content( item_node, './/@idref', nil )
      @log.debug( "Found parent link to '#{parent_id}'" )
      # node ids are held on action nodes (which are 1-1 parent of project nodes, hence 2nd check)
      id = item_node[ 'id' ] || item_node.parent[ 'id' ]
      @ref_to_node[  id ]  = item 
      @parent_ref_of[ item ] = parent_id
    end
    
    def for_sorted( node_type )
      nodes = @xml.xpath( "/xmlns:omnifocus/xmlns:#{node_type}" )
      nodes.sort_by{ | n | xpath_content( n, './xmlns:rank' ).to_i }
    end
    
    def xpath_content( node, xpath, default = "" )
      result = node.at_xpath( xpath )
      result ? result.content : default
    end
    
    
    def foreach_archive_xml
      @log.debug( "untarring #{@directory}/#{@filename} for #{@username}" )
      begin
        Archive::Tar::Minitar.unpack "#{@directory}/#{@filename}", "."
        
        FileUtils.mv( @username, @directory )
        
        @log.debug( "unzipping entries in archive: #{@directory}/#{@username}/OmniFocus.ofocus/" )
        full_path = "#{@directory}/#{@username}/OmniFocus.ofocus"
        Dir.foreach( full_path ) do | file |
          if( /\.zip$/ =~ file )
            @log.debug("Found zip file #{file}")
            Zip::ZipFile.open( "#{full_path}/#{file}" ) do |zipfile|
              yield zipfile.file.read( "contents.xml" )
            end
          end
        end
        return "Ok"
      ensure
        @log.debug("Cleaning up afterwards")
        FileUtils.rm_r("#{@directory}/#{@username}")
      end
    end
  end
end
