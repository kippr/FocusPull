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

  class ExclusionConfigMatcher

    def initialize expected = []
      @expected = expected
    end

    def matches? target
      @target = target
      @target.exclusions == @expected
    end

    def failure_message
      "expected #{@expected} as exclusions, but got #{@target.exclusions}"
    end

    def negative_failure_message
      "expected #{@expected} not to be the exclusions"
    end

  end

  def use_exclusions *expected_exclusions
    ExclusionConfigMatcher.new expected_exclusions
  end

  def use_default_exclusions
    ExclusionConfigMatcher.new
  end

end
