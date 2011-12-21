class FocusConfig

  def period_description
    "last 2 weeks"
  end

  def exclusion_description
    ( @exclusions && @exclusions.to_s ) || "Nothing"
  end

  def exclusions
    @exclusions || []
  end

  def exclusions= exclusion_string
    @exclusions = ( exclusion_string || "" ).split( %r{,\s*} )
  end

end
