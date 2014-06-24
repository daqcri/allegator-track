class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def limit_query(query)
    start = params[:start].to_i
    length = params[:length].to_i
    query = query.offset(start)
    query = query.limit(length) if length > 0
  end
end
