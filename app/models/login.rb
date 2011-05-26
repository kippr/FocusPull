class Login
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  
  attr_accessor :name
  attr_accessor :password
  
  def initialize params
    @name = params[ :name ] || "kippr"
    @password = params[ :password ]
  end
  
  def persisted?
    false
  end
  
  
end