class DatasetsController < ApplicationController

  before_filter :authenticate_user!

  def create
    # TODO: RECEIVE MULTIPLE

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
    render json: {
      claims: current_user.datasets.where(kind: 'claims').order(:created_at),
      ground: current_user.datasets.where(kind: 'ground').order(:created_at)
    }
  end

  def destroy
    # TODO USE cancan to load_and_authorize resource
    # @dataset.destroy
  end
end
