class RunsController < ApplicationController

  before_filter :authenticate_user!

  def create
    params[:checked_algo].each do |algo_name, algo_params|
      logger.debug("algorithm: #{algo_name} with params: #{algo_params}")
      run = Run.create algorithm: algo_name,
        general_config: params[:general_config].join(" "),
        config: algo_params.join(" "),
        user: current_user
      run.datasets = current_user.datasets

      run.delay.start
    end

    render json: {status: 'OK'}
  end
  
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
  end
end
