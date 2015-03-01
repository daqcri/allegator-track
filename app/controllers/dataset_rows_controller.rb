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

    single_field = params[:extra_only]

    # basic query
    query = DatasetRow.joins(:dataset)
      .where("dataset_rows.dataset_id" => datasets)

    # CALCULATING TOTAL COUNT
    total = query_count(query, single_field)

    # FILTERING
    if params[:search][:value].present?
      fields = single_field.present? ? [single_field] : %w(object_key source_id property_key property_value timestamp)
      criteria = params[:search][:value]
      query = query.where fields.map{|f| "LOWER(#{f}) like LOWER('%#{criteria}%')"}.join(" OR ")
      filtered = query_count(query, single_field)
    else
      filtered = total
    end

    # select more counts in single_field mode
    if single_field
      query = query.select("#{single_field}, count(distinct dataset_rows.id) uclaims, count(distinct dataset_rows.object_key) uobjs")
        .group(single_field)
    end

    # SORTING
    if params[:order]
      sort = params[:order]["0"]
      sort_col = params[:columns][sort["column"]]["data"]
      sort_col = 'dataset_rows.id' if sort_col == 'claim_id'  # TODO hack until we rename dataset_rows table to claims
      sort_dir = sort["dir"]
      query = query.order("#{sort_col} #{sort_dir}")
    end

    # DISTINCT ROWS
    # EXPERIMENTAL: DISABLING FOR SPEED
    # query = query.distinct

    # LIMITING QUERY
    query = limit_query(query)

    # RENDERING
    query = query.map{|row|
      o = {}
      o[single_field] = row[single_field]
      o['uclaims'] = row['uclaims']
      o['uobjs'] = row['uobjs']
      o
    } if single_field.present?

    render json: {
      draw: params[:draw].to_i,
      recordsTotal: total,
      recordsFiltered: filtered,
      data: query
    }
  end

private

  def query_count(query, single_field)
    if single_field.present?
      query.select(single_field).distinct.count
    else
      query.distinct.count
    end
  end

end
