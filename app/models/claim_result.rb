class ClaimResult < ActiveRecord::Base
  belongs_to :run

  def self.initialize_from_row(row, run)
    cr = run.claim_results.build
    cr.claim_id = row[:claimid].to_i
    cr.confidence = row[:confidence].to_f
    cr.is_true = row[:istrue] == "true"
    cr.bucket_id = row[:bucketid].to_i
    cr
  end

  def self.export_header
    %w(ClaimId Confidence IsTrue BucketId)
  end

  def export
    [claim_id, confidence, is_true, bucket_id]
  end
end
