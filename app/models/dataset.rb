require './app/uploaders/csv_uploader.rb'

class Dataset < ActiveRecord::Base
  belongs_to :user
  has_many :dataset_rows, dependent: :destroy, autosave: true

  mount_uploader :upload, CsvUploader

  def to_s
    self.upload.current_path
  end

  def parse_upload
    require 'csv'
    CSV.parse(self.upload.read, {:headers => true, :return_headers => false, :header_converters => :symbol, :converters => :all}) do |row|
      DatasetRow.initialize_from_row(row, self)
    end
    self.save!
  end

  def row_count
    self.dataset_rows.count
  end

  def as_json(options={})
    options = {
      :only => [:id, :kind, :original_filename, :created_at],
      :methods => [:row_count]
    }.merge(options)
    super(options)
  end

end
