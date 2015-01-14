require 'csv'

class RunsetsController < ApplicationController

  # for csv export streaming
  # include ActionController::Live

  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:create, :index]

  def create
    datasets = current_user.datasets.pluck(:id)
    if params[:datasets].present? && params[:datasets].respond_to?(:keys)
      datasets = params[:datasets].keys.map(&:to_i)
    end
    runset = Runset.create user: current_user, dataset_ids: datasets
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
    total, filtered, results_type, claim_cols, query = @runset.results(params)

    respond_to do |format|
      format.json {
        # showing table, apply offset/limit
        query = limit_query(query)
        logger.info("Retrieving results from arel generated sql: #{query.to_sql}")

        data = @runset.hash_results(query, results_type, claim_cols)

        render json: {
          draw: params[:draw].to_i,
          recordsTotal: total,
          recordsFiltered: filtered,
          data: data
        }        
      }
      format.csv {
        # exporting csv, retrieve all data at once!
        logger.info("Exporting results from arel generated sql: #{query.to_sql}")

        filename = params[:extra_only] == "source_id" ? "source" : "claim"

        headers['Content-Disposition'] = "attachment; filename=#{filename}_results_runset_#{@runset.id}_#{@runset.dataset_names}.csv"
        headers['X-Accel-Buffering'] = 'no'
        headers['Cache-Control'] = 'no-cache'

        self.response_body = Enumerator.new do |receiver|
          start, length = 0, 1000
          while start < filtered
            params[:start], params[:length] = start, length
            data = @runset.hash_results(limit_query(query), results_type, claim_cols)

            receiver << CSV.generate_line(data[0].keys.map{|key|
              m = key.match(/^r([\d]+)$/)
              key + (m ? ": #{Run.find(m[1].to_i).display}" : "")
            }) if start == 0

            data.each do |row|
              receiver << CSV.generate_line(row.values)
            end

            puts "written chunk of #{length} lines starting from #{start}"

            start += length
          end
        end

      }
    end

  end

end
