class RunObserver < ActiveRecord::Observer
  def after_commit(run)
    runset = run.runset.reload

    # if all runs in parent runset are done, run combiners if any
    return if runset.status != "combinable"

    # calculate combiners
    Rails.logger.info "Now calculating combiners for runset #{runset.id} through run #{run.id}"

    runset.combiner_runs.each do |run|
      run.delay.start
    end
  end
end
