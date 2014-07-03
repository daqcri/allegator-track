class RunsetsController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:create, :index]

  def create
    runset = Runset.create user: current_user, datasets: current_user.datasets
    params[:checked_algo].each do |algo_name, algo_params|
      runset.runs.create(algorithm: algo_name,
        general_config: params[:general_config].join(" "),
        config: algo_params.join(" "))
      .delay.start
    end

    render json: runset
  end

  def index
    runsets = current_user.runsets

    render json: runsets
  end

  def destroy
    @runset.destroy
    render json: {status: 'OK'}
  end

end
