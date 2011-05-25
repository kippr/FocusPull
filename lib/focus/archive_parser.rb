
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
  
    def xpath_content( node, xpath )
      result = node.at_xpath( xpath )
      result ? result.content : ""
    end
    
    #todo: remove duplication with parse_folders, also rank now
    def parse_actions( xml )
      xml.xpath( '/xmlns:omnifocus/xmlns:task' ).each do | actionNode |
        @log.debug( "Found node: #{actionNode}")
        name = xpath_content( actionNode, './xmlns:name' )
        rank = xpath_content( actionNode, './xmlns:rank' )
        projectNode = actionNode.at_xpath( './xmlns:project' )
        
        if projectNode.nil?
        
          item = Action.new( name, rank )

          track_links( item, actionNode )
                  
        else
        
          item = Project.new( name, rank )

          statusNode = projectNode.at_xpath( './xmlns:status' )
          item.status = statusNode.content unless statusNode.nil?
          item.set_single_actions if projectNode.at_xpath( './xmlns:singleton' )      
                    
          track_links( item, projectNode )
          
        end

        # todo: duplication
        added_node = actionNode.at_xpath( './xmlns:added' )
        item.created_date = added_node.content if added_node

        modified_node = actionNode.at_xpath( './xmlns:modified' )
        item.updated_date = modified_node.content if modified_node

        completed_node = actionNode.at_xpath( './xmlns:completed' )
        item.completed( completed_node.content ) if completed_node
        
      end
    end
    
    def parse_folders( xml )
      xml.xpath('/xmlns:omnifocus/xmlns:folder').each do | folderNode |
        @log.debug( "Found folder: #{folderNode} with id #{folderNode.attribute( "id").content}" )
        
        name = xpath_content( folderNode, './xmlns:name' )
        rank = xpath_content( folderNode, './xmlns:rank' )
        folder = Folder.new( name, rank )
        track_links( folder, folderNode )        
    
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
