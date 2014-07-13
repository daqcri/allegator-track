class ClaimResult < ActiveRecord::Base
  belongs_to :run

  def self.initialize_from_row(row, run)
    cr = run.claim_results.build
    cr.claim_id = row[:claimid]
    cr.confidence = row[:confidence].to_f
    cr.is_true = row[:istrue] == "true"
    cr.bucket_id = row[:bucketid].to_i
    cr
  end

end
