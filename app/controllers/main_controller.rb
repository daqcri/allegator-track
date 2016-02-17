class MainController < ApplicationController
  before_filter :authenticate_user_from_token!, except: 'landing'
  before_filter :authenticate_user!, except: ['landing', 'guest']

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

  def guest
    if ENV['ALLOW_GUEST_ACCESS'] == '1'
      user = User.guest
      sign_in(user, bypass: true)
      redirect_to after_sign_in_path_for(user)
    else
      render status: :forbidden, text: "<h1>Forbidden</h1>"
    end
  end

end
