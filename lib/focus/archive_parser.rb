
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
      xml = Nokogiri::XML( content )
      parse_actions( xml )
      parse_folders( xml )
    end
    
    resolve_links
    root
  end

  private
  
    def xpath_content( node, xpath, default = "" )
      result = node.at_xpath( xpath )
      result ? result.content : default
    end
    
    #todo: remove duplication with parse_folders, also rank now
    def parse_actions( xml )
      xml.xpath( '/xmlns:omnifocus/xmlns:task' ).each do | action_node |
        @log.debug( "Found node: #{action_node}")
        name = xpath_content( action_node, './xmlns:name' )
        rank = xpath_content( action_node, './xmlns:rank' )
        projectNode = action_node.at_xpath( './xmlns:project' )
        
        if projectNode.nil?

          item = Action.new( name, rank )
          track_links( item, action_node )
                  
        else
        
          item = Project.new( name, rank )
          statusNode = projectNode.at_xpath( './xmlns:status' )
          item.status = statusNode.content unless statusNode.nil?
          item.set_single_actions if projectNode.at_xpath( './xmlns:singleton' )      
                    
          track_links( item, projectNode )
          
        end

        item.created_date = xpath_content( action_node, './xmlns:added', nil )
        item.updated_date = xpath_content( action_node, './xmlns:modified', nil )
        item.completed( xpath_content( action_node, './xmlns:completed', nil ) )
        
      end
    end
        
    def parse_folders( xml )
      xml.xpath('/xmlns:omnifocus/xmlns:folder').each do | folder_node |
        @log.debug( "Found folder: #{folder_node} with id #{folder_node.attribute( "id").content}" )
        
        name = xpath_content( folder_node, './xmlns:name' )
        rank = xpath_content( folder_node, './xmlns:rank' )
        folder = Folder.new( name, rank )
        track_links( folder, folder_node )        
    
      end
    end
    
    # This is going to need cleanup, esp when we get to actions, where path is different
    def track_links( item, itemNode )
      #keep track of links for parent <-> kids
      parentLink = itemNode.at_xpath( './xmlns:folder/@idref' ) || itemNode.at_xpath( './xmlns:task/@idref' )
      @log.debug( "Found parent link to '#{parentLink}'" )
      # need the 'or' for project nodes, which are structured as sub-els of actions
      # todo: clean this up
      id = ( itemNode[ 'id' ] || itemNode.parent['id'] )
      @ref_to_node[  id ]  = item 
      @parent_ref_of[ item ] = parentLink && parentLink.content   
    end
    
    def resolve_links
      @log.debug( "Resolving links for #{@ref_to_node}")
      @ref_to_node.each_pair do | ref, node |
        # replace the string key ref we stored on each node with the actual parent
        node.link_parent( @ref_to_node[ @parent_ref_of[ node ] ] )
      end
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
