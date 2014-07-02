class DatasetRowsController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:index]

  def index
    if params[:extra_run_ids].present?
      conn = ActiveRecord::Base.connection
      run_ids = params[:extra_run_ids]
      if params[:extra_only] == "source_id"
        # attach source trustworthiness
        r1 = run_ids.first
        select = run_ids.map{|r| "round (r#{r}.trustworthiness * 10000)/10000 r#{r}"}.join(',')
        from = "FROM source_results r#{r1}"
        # remove the first run id
        run_ids.delete_at(0)
        joins = run_ids.map{|r| "INNER JOIN source_results r#{r} ON r#{r}.run_id = #{r} AND r#{r1}.source_id = r#{r}.source_id"}.join("\n")
        # put back the first run id
        run_ids.unshift r1
        where = "WHERE r#{r1}.run_id = #{r1}"
        order = ""
        # sorting
        if params[:order]
          sort = params[:order]["0"]
          sort_col = params[:columns][sort["column"]]["data"]
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
        if params[:search][:value].present?
          criteria = params[:search][:value]
          fields = params[:extra_only].blank? ? %w(claim_id object_key source_id property_key property_value timestamp) : [params[:extra_only]]
          where += " AND (" + fields.map{|f| "LOWER(r#{r1}.#{f}) like LOWER('%#{criteria}%')"}.join(" OR ") + ")"
        end
        criteria = params[:extra_object_key_criteria]
        where += " AND (LOWER(object_key) like LOWER('%#{criteria}%'))" unless criteria.blank?
        criteria = params[:extra_source_id_criteria]
        where += " AND (LOWER(source_id) like LOWER('%#{criteria}%'))" unless criteria.blank?

        sql = "SELECT COUNT(*) #{from} #{joins} #{where}"
        filtered = conn.select_value(sql)

        sql = "SELECT r#{r1}.source_id source_id, #{select}
          #{from} #{joins} #{where} #{order} #{limit} #{offset}"
        data = conn.select_all(sql)

        render json: {
          draw: params[:draw].to_i,
          recordsTotal: total,
          recordsFiltered: filtered,
          data: data
        }
        return
      elsif params[:extra_only].blank?
        # attach claim confidences
        return
      end
    end

    query = current_user.dataset_rows

    # SORTING
    if params[:order]
      sort = params[:order]["0"]
      sort_col = params[:extra_only] || params[:columns][sort["column"]]["data"]
      sort_dir = sort["dir"]
      
      query = query.order("#{sort_col} #{sort_dir}")
    end

    # CALCULATING TOTAL COUNT
    if params[:extra_only].blank?
      total = query.select("claim_id").distinct.count
    else
      total = query.select(params[:extra_only]).distinct.count
    end

    # FILTERING
    if params[:search][:value].present?
      criteria = params[:search][:value]
      fields = params[:extra_only].blank? ? %w(claim_id object_key source_id property_key property_value timestamp) : [params[:extra_only]]
      query = query.where fields.map{|f| "LOWER(#{f}) like LOWER('%#{criteria}%')"}.join(" OR ")
    end
    criteria = params[:extra_object_key_criteria]
    query = query.where "LOWER(object_key) like LOWER('%#{criteria}%')" unless criteria.blank?
    criteria = params[:extra_source_id_criteria]
    query = query.where "LOWER(source_id) like LOWER('%#{criteria}%')" unless criteria.blank?

    # DISTINCT ROWS
    query = query.distinct

    # CALCULATING FILTERED COUNT
    filtered = query.count(params[:extra_only].blank? ? "claim_id" : params[:extra_only])

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
