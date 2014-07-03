class RunsController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:index]

  def index
    query = current_user.runs.order(created_at: :desc)

    query = limit_query(query)

    render json: {
      draw: params[:draw].to_i,
      recordsTotal: query.length,
      recordsFiltered: query.length,
      data: query
    }
  end

  def destroy
    @run.destroy
    render json: {status: 'OK'}
  end
end
