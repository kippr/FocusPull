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

    def initialize expected_description, expected = []
      @expected_description = expected_description
      @expected = expected
    end

    def matches? target
      @target = target
      @exclusions_match = @target.exclusions == @expected
      @descriptions_match = @target.exclusions_description == @expected_description
      @exclusions_match && @descriptions_match
    end

    def failure_message
      unless @descriptions_match
        "expected #{@expected_description} but got #{@target.exclusions_description}"
      else
        "expected #{@expected} as exclusions, but got #{@target.exclusions}"
      end
    end

  end

  def use_exclusions *expected_exclusions
    ExclusionConfigMatcher.new expected_exclusions.join( ", " ), expected_exclusions
  end

  def use_default_exclusions
    ExclusionConfigMatcher.new "Nothing"
  end

end
