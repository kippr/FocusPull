class Notice
  
  def initialize msg
    @msg = msg
    @create_time = Time.now
  end
  
  def message
    "#{f_create_time} - #{@msg}"
  end
  
  def id
    "#{type}-#{@create_time.to_i}"
  end
  
  def type
    "notice"
  end
  
  def to_s
    "#{self.class.name} - #{self.message}"
  end
  
  private
    def f_create_time
      @create_time.strftime("%H:%M:%S")
    end
    
end
