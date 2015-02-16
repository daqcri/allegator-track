class MainController < ApplicationController
  before_filter :authenticate_user_from_token!  
  before_filter :authenticate_user!

  def index
    if current_user.has_gui_access
      @current_user = current_user
    else
      render status: :forbidden, action: 'nogui', layout: false
    end
  end
 
end
