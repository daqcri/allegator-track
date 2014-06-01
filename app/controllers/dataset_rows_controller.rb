class DatasetRowsController < ApplicationController
  
  before_filter :authenticate_user!

  def index
    total = current_user.dataset_rows.count
    start = params[:start].to_i
    length = params[:length].to_i
    length = total if length == -1
    data = current_user.dataset_rows.offset(start).limit(length)

    if params[:order]
      sort = params[:order]["0"]
      sort_col = params[:columns][sort["column"]]["data"]
      sort_asc = sort["dir"] == "asc"
      
      data = data.order("#{sort_col} #{sort_asc ? 'asc' : 'desc'}")
    end
    render json: {
      draw: params[:draw].to_i,
      recordsTotal: total,
      recordsFiltered: total,
      data: data
    }
  end

end
