class DatasetRow < ActiveRecord::Base

  belongs_to :dataset

  validates :object_key, :property_key, :property_value, presence: true
  validates :source_id, presence: true, unless: :ground?

  def self.create_from_row(row, dataset)
    dsr = dataset.dataset_rows.build
    # read raw values
    dsr.object_key = (row[:objectid] || row[:object_id] || row[:objectkey] || row[:object_key]).try(:strip)
    dsr.property_key = (row[:propertyid] || row[:property_id] || row[:propertykey] || row[:property_key]).try(:strip)
    dsr.property_value = (row[:propertyvalue] || row[:property_value] || row[:propertyvalues] || row[:property_values]).try(:strip)
    unless dsr.ground?
      dsr.source_id = (row[:sourceid] || row[:source_id]).try(:strip)
      dsr.timestamp = (row[:timestamp] == 'null' ? '' : row[:timestamp]).try(:strip)
    end
    dsr.user_id = dataset.user.id
    begin
      dsr.save!
    rescue => e
      dsr.destroy
      raise e
    end

    return unless dataset.multi

    # multi
    values = dsr.property_value.split /\s*,\s*/
    if values.length > 1
      values.each do |value|
        child_dsr = dsr.dup
        child_dsr.property_value = value.strip
        child_dsr.parent_id = dsr.id
        child_dsr.save! rescue child_dsr.destroy
      end
    else  # property_values can't be split
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

  def export(value_to_boolean)
    k, v = property_key, property_value
    if value_to_boolean
      k = "#{k}_#{v}"
      v = true
    end
    if ground?
      [object_key, k, v]
    else
      [claim_id, object_key, k, v, source_id, timestamp||"null"]
    end
  end

  def ground?
    self.dataset.ground?
  end

  def as_json(options={})
    options = {
      :only => [:object_key, :property_key, :property_value, :source_id, :timestamp, :parent_id],
      :methods => [:claim_id]
    }.merge(options)
    super(options)
  end
end
