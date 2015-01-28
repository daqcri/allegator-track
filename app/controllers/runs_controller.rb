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

  def visualize
      render json: @run.sankey

    # render json: {nodes:[
    #   {name: "Best Bargain Books"},
    #   {name: "textbookxdotcom"},
    #   {name: "OPOE-ABE Books"},
    #   {name: "Player Quest"},
    #   {name: "Bobs Books"},
    #   {name: "Mellon's Books"},
    #   {name: "Blackwell Online"},
    #   {name: "1"},
    #   {name: "2"},
    #   {name: "3"},
    #   {name: "4"},
    #   {name: "True"},
    #   {name: "False"}
    #   ],
    #   links:[
    #   { source:0, target:7, value:2},
    #   { source:7, target:11, value:3},
    #   { source:1, target:10, value:6}, 
    #   { source:10, target:12, value:5},
    #   { source:1, target:9, value:5},
    #   { source:2, target:9, value:3},
    #   { source:9, target:11, value:1},
    #   { source:2, target:10, value:8},
    #   { source:3, target:8, value:4},
    #   { source:8, target:11, value:6},
    #   { source:4, target:8, value:15},
    #   { source:8, target:12, value:4},
    #   { source:5, target:7, value:10},
    #   { source:9, target:12, value:4},
    #   { source:6, target:8, value:4},
    #   { source:8, target:12, value:6},
    #   { source:6, target:10, value:9},
    #   { source:10, target:11, value:1},
    #   { source:6, target:7, value:9},
    #   { source:7, target:11, value:1}
    # ]}
  end

  def destroy
    @run.destroy
    render json: {status: 'OK'}
  end

  def explain
    if params[:claim_id].blank?
      render body: @run.explain_tree, content_type: "application/xml; charset=utf-8"
    else
      render json: (@run.explain(params[:claim_id]) rescue {})
    end
  end
end

