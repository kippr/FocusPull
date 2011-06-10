class Notice
  
  def initialize msg
    @msg = msg
    @create_time = Time.now
    @default_period = 7000
  end
  
  def id
    "#{type}-#{@create_time.to_i}"
  end
  
  def type
    "notice"
  end
  
  def period
    @default_period
  end
  
  def message
    @msg
  end
  
  def to_s
    "#{self.class.name} - #{self.message}"
  end
      
end
