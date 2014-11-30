require 'open-uri'
require 'csv'

class Dataset < ActiveRecord::Base
  belongs_to :user
  has_many :dataset_rows, dependent: :destroy, autosave: true
  has_and_belongs_to_many :runsets

  def to_s
    "Dataset ##{id}: #{original_filename}"
  end

  def before
    push_status 'processing'
  end

  def parse_upload
    csv_opts = {:headers => true, :return_headers => true, :header_converters => :symbol}
    CSV.foreach(read_file, csv_opts) do |row|
      unless row.header_row?
        DatasetRow.initialize_from_row(row, self)
      else
        self.multi = !!row[:propertyvalues] || !!row[:property_values]
      end
    end
    self.save!
  end

  def success
    push_status 'done'
  end

  def error
    push_status 'failed'
  end

  def row_count
    self.dataset_rows.count
  end

  def export(path, single_valued_algo = false, value_to_boolean = false)
    CSV.open(path, "wb") do |csv|
      csv << export_header
      dataset_rows.each do |row|
        if single_valued_algo # e.g. Cosine
          csv << row.export(value_to_boolean) if row.single_valued?
        else # e.g. LTM
          csv << row.export(value_to_boolean) if row.multi_valued?
        end
      end
    end
  end

  def export_header
    if self.kind == 'ground'
      %w(ObjectID PropertyID PropertyValue)
    else
      %w(ClaimID ObjectID PropertyID PropertyValue SourceID TimeStamp)
    end
  end

  def as_json(options={})
    options = {
      :only => [:id, :kind, :original_filename, :created_at, :status],
      :methods => [:row_count]
    }.merge(options)
    super(options)
  end

  def destroy
    # overriding destroy to be more efficient by issuing only 3 SQL deletes
    # rather than 1 + dataset_rows.count !
    conn = ActiveRecord::Base.connection
    conn.execute("DELETE FROM dataset_rows WHERE dataset_id = #{self.id}")    
    super # continue from super to call all after_destroy callbacks
  end

private
  
  def read_file
    # streaming download from S3
    if(self.s3_key)
      file = Tempfile.new("import-#{self.id}-")
	    S3_BUCKET.objects[self.s3_key].read do |chunk|
	      file.write chunk
	    end
      file.close
      return file.path
    elsif(self.other_url)
      # streaming download from other locations
      file = open(self.other_url)
      file.close
      return file.path
    end
  end

  def push_status(status)
    self.status = status
    self.save!
    Pusher.trigger("user_#{self.user.id}", 'dataset_change', self)
  end
end
