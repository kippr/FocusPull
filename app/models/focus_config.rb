class FocusConfig

  def period_description
    "last 2 weeks"
  end

  def exclusions_description
    exclusions.empty? ? "Nothing" : exclusions.join( ", " )
  end

  def exclusions
    @exclusions || []
  end

  def exclusions= exclusion_string
    if exclusion_string.nil? || exclusion_string.blank?
      @exclusions = []
    else
      @exclusions = exclusion_string.split( %r{,\s*} ) if exclusion_string
    end
  end

end
