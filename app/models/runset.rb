require 'set'

class Runset < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :datasets
  has_many :dataset_rows, through: :datasets

  has_many :runs, dependent: :destroy
  has_many :source_results, through: :runs
  has_many :claim_results, through: :runs

  def status
    run_statuses = self.runs.map(&:status).uniq
    # return finished if all runs are finished
    return "finished" if run_statuses == ["finished"]
    # return started if at least 1 run started
    return "started" if run_statuses.include?("started")
    # return combinable if all scheduled are combiners and all combiners are scheduled
    return "combinable" if Set.new(scheduled_runs) == Set.new(combiner_runs)
    # return scheduled otherwise
    return "scheduled"
  end

  def combiner_runs
    runs.select &:combiner?
  end

  def non_combiner_runs
    runs.reject &:combiner?
  end

  def scheduled_runs
    runs.select &:scheduled?
  end

  def as_json(options={})
    options = {
      :only => [:id, :created_at],
      :include => {
        :runs => {
          :only => [:id, :algorithm, :created_at],
          :methods => [:display, :status, :duration]
        }
      }
    }.merge(options)
    super(options)
  end

  def to_s
    "Runset ##{id}"
  end
end
