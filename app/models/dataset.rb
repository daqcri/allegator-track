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
    # destroy old inputs, in case job was restarted
    destroy_associations!
  end

  def parse_upload
    csv_opts = {:headers => true, :return_headers => true, :header_converters => :symbol}
    self.duplicate_rows = self.invalid_rows = 0 

    # read_file = File.open(Rails.root + 'test.csv')
    
    stream = read_file
    string = detect_encoding_convert stream.read
    CSV.parse(string, csv_opts) do |row|
      unless row.header_row?
        begin
          DatasetRow.create_from_row(row, self)
        rescue ActiveRecord::RecordInvalid => e
          self.invalid_rows += 1
          Rails.logger.debug ">>> db error [#{e.class.name}] #{e.message}"
        rescue => e
          self.duplicate_rows += 1 if e.message.match(/PG::UniqueViolation/)
          Rails.logger.debug ">>> db error [#{e.class.name}] (dups: #{self.duplicate_rows}) #{e.message}"
        end
      else
        self.multi = !!row[:propertyvalues] || !!row[:property_values]
      end
      push_status
    end
  ensure
    stream.close
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
    if ground?
      %w(ObjectID PropertyID PropertyValue)
    else
      %w(ClaimID ObjectID PropertyID PropertyValue SourceID TimeStamp)
    end
  end

  def ground?
    self.kind == 'ground'
  end

  def as_json(options={})
    options = {
      :only => [:id, :kind, :original_filename, :created_at, :status, :duplicate_rows, :invalid_rows],
      :methods => [:row_count]
    }.merge(options)
    super(options)
  end

  def destroy
    destroy_associations!
    super
  end

private
  
  def destroy_associations!
    # overriding destroy to be more efficient by issuing only 3 SQL deletes
    # rather than 1 + dataset_rows.count !
    conn = ActiveRecord::Base.connection
    conn.execute("DELETE FROM dataset_rows WHERE dataset_id = #{self.id}")
  end

  def read_file
    # streaming download from S3
    if self.s3_key
      file = Tempfile.new("import-#{self.id}-")
      file.binmode
	    S3_BUCKET.objects[self.s3_key].read do |chunk|
	      file.write chunk
	    end
      file.rewind
      file
    elsif self.other_url
      # streaming download from other locations
      file = open(self.other_url)
      file.rewind
      file
    end
  end

  def push_status(status = nil)
    @last_push ||= Time.now - 1.year
    if status # status has changed
      self.status = status
    elsif Time.now - @last_push < 10.seconds # if some time passed, push updated count
      return
    end
    logger.debug("saving ds: #{self.save}, status = #{status}, dups: #{self.duplicate_rows}")
    Pusher.trigger_async("user_#{self.user.id}", 'dataset_change', self)
    @last_push = Time.now
  end

  def detect_encoding_convert(body)
    detection = CharlockHolmes::EncodingDetector.detect(body)
    logger.debug "charlock holmes detected #{detection}"
    # Remove BOM Characters
    if (detection[:encoding] == 'UTF-8')
      body.force_encoding("UTF-8").sub("\xEF\xBB\xBF", "")
    else
      CharlockHolmes::Converter.convert(body, detection[:encoding], 'UTF-8')
    end
  end

end
