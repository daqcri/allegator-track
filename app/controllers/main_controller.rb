class MainController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
 
  def run
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

end
