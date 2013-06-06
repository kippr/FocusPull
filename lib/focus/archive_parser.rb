
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
    @root = Focus.new
    @ref_to_node = Hash.new
    @parent_ref_of = Hash.new
    @context_ref_of = Hash.new
    @ranking = Hash.new( 0 )

    foreach_archive_xml do | content |
      @xml = Nokogiri::XML( content )
      parse_actions
      parse_folders
      parse_contexts
    end

    resolve_links
    @root
  end

  private

    def parse_actions
      for_each( "task" ).each do | action_node |
        @log.debug( "Processing action: #{action_node}")
        project_node = action_node.at_xpath( './xmlns:project' )
        if project_node
          item = create_node( action_node, Project )
          item.status = xpath_content( project_node, './xmlns:status', nil)
          item.set_single_actions if project_node.at_xpath( './xmlns:singleton' )
        else
          item = create_node( action_node, Action )
        end
        item.start_date = xpath_content( action_node, './xmlns:start', nil )
        item.completed( xpath_content( action_node, './xmlns:completed', nil ) )
      end
    end

    def parse_folders
      for_each( 'folder' ).each do | folder_node |
        @log.debug( "Processing folder: #{folder_node}" )
        create_node( folder_node, Folder )
      end
    end

    def parse_contexts
      for_each( "context" ).each do | context_node |
        @log.debug( "Processing context: #{context_node}" )
        item = create_node( context_node, Context )
        if context_node.at_xpath './xmlns:prohibits-next-action'
          item.status = :inactive
        end
      end
    end


    def create_node( node, type )
      name = xpath_content( node, './xmlns:name' )
      # for very weird bugs, this is useful
      # name = "#{name}-#{node[ 'id' ]}"
      item = type.new( name )
      item.created_date = xpath_content( node, './xmlns:added', nil )
      item.updated_date = xpath_content( node, './xmlns:modified', nil )
      if node[ 'op' ] == "delete"
        remove_links( node )
      else
        track_links( item, node )
      end
      item
    end

    def track_links( item, item_node )
      # parent id is held as idref
      parent_id = xpath_content( item_node, './/@idref', nil )
      @log.debug( "Found parent link to '#{parent_id}'" )
      # node ids are held on action nodes (which are 1-1 parent of project nodes, hence 2nd check)
      id = item_node[ 'id' ] || item_node.parent[ 'id' ]
      # todo: consider 'blank context' nullobj?
      context_id = xpath_content( item_node, './xmlns:context/@idref', nil )
      @ref_to_node[  id ]  = item
      @parent_ref_of[ id ] = parent_id
      @context_ref_of[ id ] = context_id
    end

    def remove_links( deleted_node )
      id = deleted_node[ 'id' ]
      @ref_to_node.delete( id )
      @parent_ref_of.delete( id )
      @context_ref_of.delete( id )
    end

    def resolve_links
      @ref_to_node.sort_by{ | ref, node | @ranking[ ref ] }.each do | ref, node |
        # replace the string key ref we stored on each node with the actual parent
        parent = @ref_to_node[ @parent_ref_of[ ref ] ] || @root
        #@log.error "#{node} has context ref: #{@context_ref_of[ ref ]}"
        context = @ref_to_node[ @context_ref_of[ ref ] ]
        if parent
          node.link_parent( parent, context )
        else
          @log.warn( "Found orphan node, not linking: #{node}" )
        end
      end
    end

    def for_each( node_type )
      nodes = @xml.xpath( "/xmlns:omnifocus/xmlns:#{node_type}" )
      nodes.each{ | n | @ranking[ n[ 'id' ] ] = xpath_content( n, './xmlns:rank' ).to_i }
      nodes
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
        Dir.foreach( full_path ).sort.each do | file |
          if( /\.zip$/ =~ file )
            @log.debug("Found zip file #{full_path}/#{file}")
            Zip::ZipFile.open( "#{full_path}/#{file}" ) do |zipfile|
              yield zipfile.read( "contents.xml" )
            end
          end
        end
        return "Ok"
      ensure
        @log.debug("Cleaning up afterwards")
        FileUtils.rm_rf("#{@directory}/#{@username}")
      end
    end
  end
end
