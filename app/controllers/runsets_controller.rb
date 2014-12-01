require 'csv'

class RunsetsController < ApplicationController

  # for csv export streaming
  # include ActionController::Live

  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:create, :index]

  def create
    runset = Runset.create user: current_user, datasets: current_user.datasets
    params[:checked_algo].each do |algo_name, algo_params|
      run = runset.runs.create(algorithm: algo_name,
        general_config: params[:general_config].join(" "),
        config: algo_params.try(:join, " "))
      run.delay.start unless run.combiner?
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
    table, table_alias, col, select_more, joins, sql_counts = "", "", "", "", "", ""

    if params[:extra_only] == "source_id"
      # attach source trustworthiness
      table = "source_results"
      table_alias = "r#{r1}"
      col = "trustworthiness"
      joins = run_ids[1..run_ids.length].map{|r| "INNER JOIN source_results r#{r} ON #{table_alias}.source_id = r#{r}.source_id"}.join("\n")
      table_cols = "id,source_id"
      # must use the manual way of inner join in order to specify the table alias so that filter_clauses work on counts and results
      sql_counts = Run.where(id: r1).joins("INNER JOIN source_results #{table_alias} ON runs.id = #{table_alias}.run_id")
    elsif params[:extra_only].blank?
      # attach claim confidences
      table = "dataset_rows"
      table_alias = "r0"
      col = "confidence"
      select_more = run_ids.map{|r| "r#{r}.is_true r#{r}_bool"}.join(',')
      joins = run_ids.map{|r| "INNER JOIN claim_results r#{r} ON #{table_alias}.id = r#{r}.claim_id"}.join("\n")
      table_cols = "*"
      sql_counts = @runset.dataset_rows.where("datasets.kind = ?", "claims")
    end

    # totals
    logger.info("Counting total")
    total = sql_counts.count

    # construct results query clauses
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

    # filtering
    filtered = total
    filter_clauses = []
    logger.info("Counting filtered")
    if params[:search].present? && params[:search][:value].present?
      criteria = params[:search][:value]
      fields = params[:extra_only].blank? ? %w(object_key source_id property_key property_value timestamp) : [params[:extra_only]]
      filter_clauses << fields.map{|f| "LOWER(#{table_alias}.#{f}) like LOWER('%#{criteria}%')"}.join(" OR ")
    end
    # don't filter on object_id/source_id when showing source results
    # in object_id case, can't get object_id from source_results without join
    # in source_id case, the filter has been already used
    if params[:extra_only].blank?
      criteria = params[:extra_object_key_criteria]
      filter_clauses << "(LOWER(object_key) like LOWER('%#{criteria}%'))" if criteria.present?
      criteria = params[:extra_source_id_criteria]
      filter_clauses << "(LOWER(source_id) like LOWER('%#{criteria}%'))" if criteria.present?
    end

    filter_clauses.each do |filter|
      sql_counts = sql_counts.where filter
      where << " AND (#{filter})"
    end
    
    filtered = sql_counts.count

    #sql = "SELECT #{table_alias}.source_id source_id, #{select + (select_more.present? ? ', ' + select_more : '')}
    table_cols = table_cols.split(',').map{|col| "#{table_alias}.#{col}"}.join(",")
    # TODO hack until we rename dataset_rows table to claims
    table_cols = "#{table_cols}, r0.id claim_id" if params[:extra_only].blank?
    sql = "SELECT #{table_cols}, #{select + (select_more.present? ? ', ' + select_more : '')}
      #{from} #{joins} #{where} #{order}"

    respond_to do |format|
      format.json {
        # showing table, apply offset/limit
        limit, offset = limit_sql
        sql = "#{sql} #{limit} #{offset}"
        logger.info("Retrieving results from custom sql: #{sql}")
        data = conn.select_all(sql)

        render json: {
          draw: params[:draw].to_i,
          recordsTotal: total,
          recordsFiltered: filtered,
          data: data
        }        
      }
      format.csv {
        # exporting csv, retrieve all data at once!
        logger.info("Exporting results from custom sql: #{sql}")

        filename = params[:extra_only] == "source_id" ? "source" : "claim"

        headers['Content-Disposition'] = "attachment; filename=#{filename}_results_runset_#{@runset.id}.csv"
        headers['X-Accel-Buffering'] = 'no'
        headers['Cache-Control'] = 'no-cache'

        self.response_body = Enumerator.new do |receiver|
          start, length = 0, 1000
          while start < filtered
            data = conn.select_all("#{sql} offset #{start} limit #{length}")

            receiver << CSV.generate_line(data[0].keys.map{|key|
              m = key.match(/^r([\d]+)$/)
              key + (m ? ": #{Run.find(m[1].to_i).display}" : "")
            }) if start == 0


            data.each do |row|
              receiver << CSV.generate_line(row.values)
            end

            # logger.info "Sleeping 5 seconds..."
            puts "written chunk of #{length} lines starting from #{start}"

            start += length
          end
        end

      }
    end

  end

end
