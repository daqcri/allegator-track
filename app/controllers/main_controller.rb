class MainController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
 
  def run
  	logger.debug(params[:config_data]["1"])
  	params[:checked_algo].each do |algo|
  		logger.debug(params[:config_data][algo])
  	end

  	logger.debug("Hello this is Zahbia #{10*20}")	
  	render json: {status: 'OK'}
  end

end
