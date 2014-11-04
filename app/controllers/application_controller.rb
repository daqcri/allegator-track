class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def limit_query(query)
    start = params[:start].to_i
    length = length=ENV['DEFAULT_DATATABLE_LENGTH'].to_i
    length = params[:length].to_i if params[:length].present?
    query = query.offset(start)
    query = query.limit(length) if length > 0
  end

  private

  def authenticate_user_from_token!
    user_token = params[:user_token].presence
    user = user_token && User.find_by_authentication_token(user_token.to_s)
 
    if user
      # Notice we are passing store false, so the user is not
      # actually stored in the session and a token is needed
      # for every request. If you want the token to work as a
      # sign in token, you can simply remove store: false.
      sign_in user
    end
  end
end
