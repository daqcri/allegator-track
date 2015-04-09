class RunsController < ApplicationController
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:index, :create]

  def index
    query = params[:allegations].present? ? Run.allegators : Run.voters
    query = query.joins(:runset).where("runsets.user_id = ?", current_user.id)
      .order("runs.created_at desc")

    query = limit_query(query)

    render json: {
      draw: params[:draw].to_i,
      recordsTotal: query.length,
      recordsFiltered: query.length,
      data: query
    }
  end

  def create
    # no need to check for authorization of run_id and claim_id
    # if they are wrong, results will just be meaningless
    # find below will raise 404 if not found
    run = Run.find params[:run_id]
    claim = DatasetRow.find params[:claim_id]
    # no allegations for combiners!
    if run.combiner? || run.allegator?
      render nothing: true, status: :bad_request
      return
    end
    # creates a new allegator run based on another run
    allegator = run.dup claim
    allegator.save
    allegator.delay.start
    render json: allegator
  end

  def sankey
    respond_to do |format|
      format.json {
        render json: @run.sankey
        #render json: Run.example_sankey
      }
      format.html {
        # template
      }
    end
  end

  def destroy
    @run.destroy
    render json: {status: 'OK'}
  end

  def explain
    respond_to do |format|
      format.json {
        if params[:claim_id].blank?
          render json: {error: 'Missing claim_id'}, status: :bad_request
        else
          begin
            json = @run.explain(params[:claim_id])
          rescue
            json = {error: 'Error generating textual explanation'}
          end
          render json: json
        end
      }
      format.xml {
        render body: @run.explain_tree, content_type: "application/xml; charset=utf-8"
      }
      format.html {
        # html template
        if params[:claim_id].blank?
          render text: 'Missing claim_id', status: :bad_request
          return
        else
          @claim = params[:claim_id]
        end
      }
    end
  end
end

