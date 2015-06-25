class MainController < ApplicationController
  before_filter :authenticate_user_from_token!, except: 'landing'
  before_filter :authenticate_user!, except: 'landing'

  def index
    if current_user.has_gui_access
      @current_user = current_user
    else
      render status: :forbidden, action: 'nogui', layout: false
    end
  end
 
  def landing
    if Rails.env.development?
      redirect_to action: 'index'
    else
      redirect_to ENV['LANDING_URL']
    end
  end
end
