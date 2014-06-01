class MainController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json {
        total = 1000000
        start = params[:start].to_i
        length = params[:length].to_i
        length = total if length == -1
        data =
          length.times.map {|n|
            ["Name #{n+1+start}", (n+1+start)*10]
          }
        if params[:order]
          sort = params[:order]["0"]
          sort_col = sort["column"].to_i
          sort_asc = sort["dir"] == "asc"
          data.sort_by!{|record| record[sort_col]}
          data.reverse! unless sort_asc
        end
        render json: {
          draw: params[:draw].to_i,
          recordsTotal: total,
          recordsFiltered: total,
          data: data
        }
      }
    end
  end

end
