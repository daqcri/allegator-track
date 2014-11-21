class RunObserver < ActiveRecord::Observer
  def after_commit(run)
    runset = run.runset.reload
    # if all runs in parent runset are done, calculate normalized
    Rails.logger.info "Before normalize: runset #{runset.id} status is #{runset.status} through run #{run.id}"
    return if runset.status != "finished"

    # calculate normalized
    Rails.logger.info "Now calculating normalized values for runset #{runset.id} through run #{run.id}"
    runset.normalize!
  end
end
