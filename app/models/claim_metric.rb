class ClaimMetric < ActiveRecord::Base
  belongs_to :run

  def self.initialize_from_row(row, run)
    cm = run.claim_metrics.build
    cm.claim_id = row[:claimid].to_i
    cm.cv = row[:cv].to_f
    cm.ts = row[:ts].to_f
    cm.min_ts = row[:mints].to_f
    cm.max_ts = row[:maxts].to_f
    cm.number_supp_sources = row[:numbersuppsources].to_f
    cm.number_opp_sources = row[:numberoppsources].to_f
    cm.total_sources = row[:totalsources].to_f
    cm.number_distinct_value = row[:numberdistinctvalue].to_f
    cm.cv_global = row[:cvglobal].to_f
    cm.local_confidence_comparison = row[:localconfidencecomparison].to_f
    cm.ts_global = row[:tsglobal].to_f
    cm.ts_local = row[:tslocal].to_f
    cm.label = row[:label] == "TRUE"
    cm
  end  

  def as_json(options={})
    options = {
      :only => [
        :cv,
        :ts,
        :min_ts,
        :max_ts,
        :number_supp_sources,
        :number_opp_sources,
        :total_sources,
        :number_distinct_value,
        :cv_global,
        :local_confidence_comparison,
        :ts_global,
        :ts_local,
        :label
      ]
    }.merge(options)
    super(options)
  end
end
