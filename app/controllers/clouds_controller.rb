class CloudsController < ApplicationController
  
  def create
    pdf = Focus::CloudFactory.create_cloud_pdf focus, "/tmp"
    send_data pdf,
              :filename => "word-cloud.pdf",
              :type => "application/pdf"
  end
    
end