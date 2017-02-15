class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  def test
    render html: "hello, world! This is a test."
  end
  
end
