class DatasetsController < ApplicationController
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!

  load_and_authorize_resource :except => [:create, :index]

  def create
    # receive uploads
    ds = Dataset.new
    ds.kind = params[:kind] || 'claims'
    ds.original_filename = params[:original_filename]
    ds.s3_key = params[:s3_key]
    ds.other_url = params[:other_url]
    ds.user = current_user
    ds.save!

    # parse
    ds.delay(queue: 'process_uploads').parse_upload
    #ds.parse_upload

    render json: {status: 'OK'}
  end

  def index
    # list all user datasets of a specified kind, generating an s3 presigned url for future uploads
    datasets = current_user.datasets.where(kind: params[:kind]).order(created_at: :desc)
    start = params[:start].to_i
    length = params[:length].to_i
    length = 10 if length <= 0
    datasets = datasets.offset(start).limit(length)
    s3_direct_post = S3_BUCKET.presigned_post(key: "import/#{SecureRandom.uuid}/${filename}", success_action_status: 201)
    render json: {
      draw: params[:draw].to_i,
      recordsTotal: datasets.length,
      recordsFiltered: datasets.length,
      data: datasets,
      s3_direct_post: {url: s3_direct_post.url.to_s, fields: s3_direct_post.fields}
    }
  end

  def destroy
    @dataset.destroy
    render json: {status: 'OK'}
  end
end
