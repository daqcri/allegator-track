class DatasetRow < ActiveRecord::Base

  belongs_to :dataset

  def self.initialize_from_row(row, dataset)
    dsr = dataset.dataset_rows.build
    dsr.claim_id = row[:claimid]
    dsr.object_id = row[:objectid]
    dsr.property_key = row[:propertyid]
    dsr.propery_value = row[:propertyvalue]
    dsr.source_id = row[:sourceid]
    dsr.timestamp = row[:timestamp] == 'null' ? nil : row[:timestamp]
    dsr
  end

  def as_json(options={})
    options = {
      :only => [:claim_id, :object_id, :property_key, :propery_value, :source_id, :timestamp],
    }.merge(options)
    super(options)
  end
end
