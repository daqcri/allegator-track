class DatasetRow < ActiveRecord::Base

  belongs_to :dataset

  def self.initialize_from_row(row, dataset)
    dsr = dataset.dataset_rows.build
    dsr.claim_id = row[:claimid] || row[:claim_id]
    dsr.object_key = row[:objectid] || row[:object_id] || row[:objectkey] || row[:object_key]
    dsr.property_key = row[:propertyid] || row[:property_id] || row[:propertykey] || row[:property_key]
    dsr.property_value = row[:propertyvalue] || row[:property_value]
    dsr.source_id = row[:sourceid] || row[:source_id]
    dsr.timestamp = row[:timestamp] == 'null' ? nil : row[:timestamp]
    dsr
  end

  def as_json(options={})
    options = {
      :only => [:claim_id, :object_key, :property_key, :property_value, :source_id, :timestamp],
    }.merge(options)
    super(options)
  end
end
