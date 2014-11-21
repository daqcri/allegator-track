class Runset < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :datasets

  has_many :runs, dependent: :destroy
  has_many :source_results, through: :runs
  has_many :claim_results, through: :runs

  def status
    run_statuses = self.runs.map(&:status)
    # return finished if all runs are finished
    return "finished" if run_statuses.uniq == ["finished"]
    # return started if at least 1 run started
    return "started" if run_statuses.include?("started") || run_statuses.include?("finished")
    # return scheduled otherwise (nothing started)
    return "scheduled"
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

  def normalize!
    normalize_association!(source_results, "trustworthiness")
    normalize_association!(claim_results, "confidence")
  end

private

  def normalize_association!(associtation, attribute)
    # get min/max
    min = associtation.minimum(attribute)
    max = associtation.maximum(attribute)
    # calculate/update normalized
    associtation.update_all("normalized = (#{attribute} - #{min}) / (#{max} - #{min})") if min && max && max-min > 1e-10
  end

end
