class RunsController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:index]

  def index
    query = current_user.runs.order(created_at: :desc)

    query = limit_query(query)

    render json: {
      draw: params[:draw].to_i,
      recordsTotal: query.length,
      recordsFiltered: query.length,
      data: query
    }
  end

  def visualize
    render json: {nodes:[
      {name: "A"},
      {name: "B"},
      {name: "C"},
      {name: "D"},
      {name: "E"},
      {name: "F"},
      {name: "G"},
      ],
      links:[
      { source:0, target:1, value:2},
      { source:2, target:3, value:20},
      { source:2, target:1, value:5}, 
      { source:4, target:2, value:5},
      { source:4, target:5, value:5},
      { source:5, target:6, value:5}
    ]}
  end

  def destroy
    @run.destroy
    render json: {status: 'OK'}
  end
end

