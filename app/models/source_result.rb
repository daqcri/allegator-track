class SourceResult < ActiveRecord::Base
  belongs_to :run

  def self.initialize_from_row(row, run)
    sr = run.source_results.build
    sr.source_id = row[:sourceid]
    sr.trustworthiness = row[:trustworthiness].to_f
    sr
  end

end
