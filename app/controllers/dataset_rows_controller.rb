class DatasetRowsController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:index]

  def index
    query = current_user.dataset_rows

    if params[:order]
      sort = params[:order]["0"]
      sort_col = params[:extra_only] || params[:columns][sort["column"]]["data"]
      sort_asc = sort["dir"] == "asc"
      
      query = query.order("#{sort_col} #{sort_asc ? 'asc' : 'desc'}")
    end

    if params[:extra_only].blank?
      total = query.select("claim_id").distinct.count
    else
      total = query.select(params[:extra_only]).distinct.count
    end

    unless params[:search][:value].blank?
      criteria = params[:search][:value]
      fields = params[:extra_only].blank? ? %w(claim_id object_id source_id property_key propery_value timestamp) : [params[:extra_only]]
      query = query.where fields.map{|f| "LOWER(#{f}) like LOWER('%#{criteria}%')"}.join(" OR ")
    end
    criteria = params[:extra_object_id_criteria]
    query = query.where "LOWER(object_id) like LOWER('%#{criteria}%')" unless criteria.blank?
    criteria = params[:extra_source_id_criteria]
    query = query.where "LOWER(source_id) like LOWER('%#{criteria}%')" unless criteria.blank?

    query = query.distinct
    filtered = query.count(params[:extra_only].blank? ? "claim_id" : params[:extra_only])

    query = limit_query(query)

    query = query.pluck(params[:extra_only]).map{|f| [f]} unless params[:extra_only].blank?

    render json: {
      draw: params[:draw].to_i,
      recordsTotal: total,
      recordsFiltered: filtered,
      data: query
    }
  end

end
