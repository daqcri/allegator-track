class MainController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      @current_user = current_user
      format.html # index.html.erb
    end
  end
 
end
