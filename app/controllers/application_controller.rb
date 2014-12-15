class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def limit_query(query)
    query = query.offset(params[:start].to_i)
    query = query.limit(compute_query_length)
  end

  def limit_sql
    offset = "OFFSET #{params[:start].to_i}"
    limit = "LIMIT #{compute_query_length}"
    return limit, offset
  end

  def after_sign_in_path_for(resource)
    main_url
  end

private

  def compute_query_length
    (params[:length] || ENV['DEFAULT_DATATABLE_LENGTH']).to_i
  end

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
