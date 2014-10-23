class DatasetRow < ActiveRecord::Base

  belongs_to :dataset

  def self.initialize_from_row(row, dataset)
    dsr = dataset.dataset_rows.build
    dsr.object_key = row[:objectid] || row[:object_id] || row[:objectkey] || row[:object_key]
    dsr.property_key = row[:propertyid] || row[:property_id] || row[:propertykey] || row[:property_key]
    dsr.source_id = row[:sourceid] || row[:source_id]
    dsr.timestamp = row[:timestamp] == 'null' ? nil : row[:timestamp]
    dsr.property_value = row[:propertyvalue] || row[:property_value]
    return unless dataset.multi

    # multi
    dsr.property_value = row[:propertyvalues] || row[:property_values]
    values = dsr.property_value.try(:strip).try(:split, /\s*,\s*/)
    dsr.save
    if values && values.length > 1
      values.each do |value|
        child_dsr = dsr.dup
        child_dsr.property_value = value
        child_dsr.parent_id = dsr.id
        child_dsr.save
      end
    else  # property_values is nil or can't be split
      dsr.parent_id = dsr.id
      dsr.save
    end
  end

  def single_valued?
    self.parent_id.nil? || self.id == self.parent_id
  end

  def multi_valued?
    !self.dataset.multi || !self.parent_id.nil?
  end

  def claim_id
    self.id
  end

  def self.export_header
    %w(ClaimID ObjectID PropertyID PropertyValue SourceID TimeStamp)
  end

  def export
    [claim_id, object_key, property_key, property_value, source_id, timestamp||"null"]
  end

  def as_json(options={})
    options = {
      :only => [:object_key, :property_key, :property_value, :source_id, :timestamp, :parent_id],
      :methods => [:claim_id]
    }.merge(options)
    super(options)
  end
end
