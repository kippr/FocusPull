class FocusConfig
  include ActionView::Helpers::DateHelper

  def period_description
    "last #{distance_of_time_in_words period_start, period_end}"
  end

  def period_start
    @start_date || 2.weeks.ago.to_date
  end

  def period_end
    Date.today
  end

  def period_start= start_date
    @start_date = start_date
  end

  def exclusions_description
    exclusions.empty? ? "nothing" : exclusions.join( ", " )
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
