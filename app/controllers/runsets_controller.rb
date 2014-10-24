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

  def results
    conn = ActiveRecord::Base.connection
    run_ids = @runset.runs.map(&:id)
    r1 = run_ids.first
    table, table_alias, col, select_more, joins = "", "", "", "", ""
    
    if params[:extra_only] == "source_id"
      # attach source trustworthiness
      table = "source_results"
      table_alias = "r#{r1}"
      col = "trustworthiness"
      joins = run_ids[1..run_ids.length].map{|r| "INNER JOIN source_results r#{r} ON #{table_alias}.source_id = r#{r}.source_id"}.join("\n")
      table_cols = "id,source_id"
    elsif params[:extra_only].blank?
      # attach claim confidences
      table = "dataset_rows"
      table_alias = "r0"
      col = "confidence"
      select_more = run_ids.map{|r| "r#{r}.is_true r#{r}_bool"}.join(',')
      joins = run_ids.map{|r| "INNER JOIN claim_results r#{r} ON #{table_alias}.id = r#{r}.claim_id"}.join("\n")
      table_cols = "*"
    end

    col = params[:extra_normalized].present? ? "normalized" : col
    select = run_ids.map{|r| "round (r#{r}.#{col} * 10000)/10000 r#{r}"}.join(',')

    from = "FROM #{table} #{table_alias}"
    where = "WHERE " + run_ids.map{|r| "r#{r}.run_id = #{r}"}.join(" AND ")
    order = ""
    # sorting
    if params[:order]
      sort = params[:order]["0"]
      sort_col = params[:columns][sort["column"]]["data"]
      sort_col = 'r0.id' if sort_col == 'claim_id'  # TODO hack until we rename dataset_rows table to claims
      sort_dir = sort["dir"]
      order = "ORDER BY #{sort_col} #{sort_dir}"
    end

    # totals
    sql = "SELECT COUNT(*) #{from} #{joins} #{where}"
    total = conn.select_value(sql)
    filtered = total

    # limiting
    start = params[:start].to_i
    length = params[:length].to_i
    offset = "OFFSET #{start}"
    limit = length > 0 ? "LIMIT #{length}" : ""

    # filtering
    if params[:search].present? && params[:search][:value].present?
      criteria = params[:search][:value]
      fields = params[:extra_only].blank? ? %w(object_key source_id property_key property_value timestamp) : [params[:extra_only]]
      where << " AND (" + fields.map{|f| "LOWER(#{table_alias}.#{f}) like LOWER('%#{criteria}%')"}.join(" OR ") + ")"
    end
    criteria = params[:extra_object_key_criteria]
    where << " AND (LOWER(object_key) like LOWER('%#{criteria}%'))" unless criteria.blank?
    criteria = params[:extra_source_id_criteria]
    where << " AND (LOWER(source_id) like LOWER('%#{criteria}%'))" unless criteria.blank?

    sql = "SELECT COUNT(*) #{from} #{joins} #{where}"
    filtered = conn.select_value(sql)

    #sql = "SELECT #{table_alias}.source_id source_id, #{select + (select_more.present? ? ', ' + select_more : '')}
    table_cols = table_cols.split(',').map{|col| "#{table_alias}.#{col}"}.join(",")
    # TODO hack until we rename dataset_rows table to claims
    table_cols = "#{table_cols}, r0.id claim_id" if params[:extra_only].blank?
    sql = "SELECT #{table_cols}, #{select + (select_more.present? ? ', ' + select_more : '')}
      #{from} #{joins} #{where} #{order} #{limit} #{offset}"
    data = conn.select_all(sql)

    if params[:export].blank?
      render json: {
        draw: params[:draw].to_i,
        recordsTotal: total,
        recordsFiltered: filtered,
        data: data
      }
    else
      require 'csv'
      if params[:extra_only] == "source_id"
        filename = "source"
      else
        filename = "claim"
      end
      csv_string = CSV.generate do |csv|
        csv << data[0].keys.map{|key|
          m = key.match(/^r([\d]+)$/)
          key + (m ? ": #{Run.find(m[1].to_i).display}" : "")
        }
        data.each do |row|
          csv << row.values
        end
      end
      send_data(csv_string, :filename => "#{filename}_results_runset_#{@runset.id}.csv")
    end
  end

end
