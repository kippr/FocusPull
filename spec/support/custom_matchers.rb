module CustomMatchers
  class TreeMapNode
    def initialize expected 
      @expected = expected
    end
    def matches? target 
      @target = target
      @target.any?{ |t| t.name == @expected }
    end
    def failure_message
      "expected #{@target.collect( &:name ).inspect} names to include #{@expected}"
    end
    def negative_failure_message
      "expected #{@target.collect( &:name ).inspect} names to not include #{@expected}"
    end
  end

  def include_tree_node expected
    TreeMapNode.new expected
  end
end
