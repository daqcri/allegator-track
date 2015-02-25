class DatasetRowsController < ApplicationController
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:index]

  def index
    # only return dataset_rows for selected datasets
    datasets = []
    if params[:datasets].present? && params[:datasets].respond_to?(:keys)
      datasets = params[:datasets].keys.map(&:to_i) & current_user.datasets.pluck(:id)
    end

    query = DatasetRow.joins(:dataset)
      .where("dataset_rows.dataset_id" => datasets)
      .where("datasets.kind" => params[:extra_kind])

    # SORTING
    if params[:order]
      sort = params[:order]["0"]
      sort_col = params[:extra_only] || params[:columns][sort["column"]]["data"]
      sort_col = 'dataset_rows.id' if sort_col == 'claim_id'  # TODO hack until we rename dataset_rows table to claims
      sort_dir = sort["dir"]
      
      query = query.order("#{sort_col} #{sort_dir}")
    end

    # CALCULATING TOTAL COUNT
    if params[:extra_only].present?
      total = query.select(params[:extra_only]).distinct.count
    elsif params[:extra_kind] == 'claims'
      total = query.select("dataset_rows.id").distinct.count
    else
      total = query.distinct.count
    end

    # FILTERING
    fields = %w(object_key source_id property_key property_value timestamp)
    # search by applying search criteria from the current table on the visible fields
    if params[:search][:value].present?
      criteria = params[:search][:value]
      qfields = params[:extra_only].blank? ? fields : [params[:extra_only]]
      query = query.where qfields.map{|f| "LOWER(#{f}) like LOWER('%#{criteria}%')"}.join(" OR ")
    end
    # search by applying search criteria from other tables
    criteria = params[:extra_object_key_criteria]
    query = query.where "LOWER(object_key) like LOWER('%#{criteria}%')" if criteria.present?
    criteria = params[:extra_source_id_criteria]
    query = query.where "LOWER(source_id) like LOWER('%#{criteria}%')" if criteria.present?
    criteria = params[:extra_criteria]
    query = query.where fields.map{|f| "LOWER(#{f}) like LOWER('%#{criteria}%')"}.join(" OR ") if criteria.present?

    # DISTINCT ROWS
    query = query.distinct

    # CALCULATING FILTERED COUNT
    filtered = query.count(params[:extra_only].present? ? params[:extra_only] : 
      (params[:extra_kind] == 'claims' ? 'dataset_rows.id' : 'id'))

    # LIMITING QUERY
    query = limit_query(query)

    # RENDERING
    query = query.pluck(params[:extra_only]).map{|f|
      # should return objects not arrays
      o = {}
      o[params[:extra_only]] = f
      o
    } unless params[:extra_only].blank?

    render json: {
      draw: params[:draw].to_i,
      recordsTotal: total,
      recordsFiltered: filtered,
      data: query
    }
  end

end
