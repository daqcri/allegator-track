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
    if params[:extra_only] == "source_id"
      # attach source trustworthiness
      r1 = run_ids.first
      col = params[:extra_normalized].present? ? "normalized" : "trustworthiness"
      select = run_ids.map{|r| "round (r#{r}.#{col} * 10000)/10000 r#{r}"}.join(',')
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
      # TODO attach claim confidences
    end
    render json: {
      draw: params[:draw].to_i,
      recordsTotal: 0,
      recordsFiltered: 0,
      data: []
    }
  end

end
