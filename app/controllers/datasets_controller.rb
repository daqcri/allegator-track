class DatasetsController < ApplicationController

  before_filter :authenticate_user!

  load_and_authorize_resource :except => [:create, :index]

  def create
    # receive uploads
    ds = Dataset.new
    ds.kind = params[:kind] || 'claims'
    ds.original_filename = params[:csv].original_filename
    ds.upload = params[:csv]
    ds.user = current_user
    ds.save!

    # parse
    ds.parse_upload

    # delete upload
    ds.upload = nil
    ds.save!

    render json: {status: 'OK'}
  end

  def index
    datasets = current_user.datasets.where(kind: params[:kind]).order(:created_at)
    start = params[:start].to_i
    length = params[:length].to_i
    length = total if length == -1
    datasets = datasets.offset(start).limit(length)
    render json: {
      draw: params[:draw].to_i,
      recordsTotal: datasets.length,
      recordsFiltered: datasets.length,
      data: datasets
    }
    

  end

  def destroy
    @dataset.destroy
    render json: {status: 'OK'}
  end
end
