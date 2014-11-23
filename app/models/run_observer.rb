class RunObserver < ActiveRecord::Observer
  def after_commit(run)
    #runset = run.runset.reload
    # if all runs in parent runset are done, run combiners
    #Rails.logger.info "Before combiners: runset #{runset.id} status is #{runset.status} through run #{run.id}"
    #return if runset.status != "finished"

    # calculate combiners
    #Rails.logger.info "Now calculating combiners for runset #{runset.id} through run #{run.id}"
  end
end
