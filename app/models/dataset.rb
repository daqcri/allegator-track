require './app/uploaders/csv_uploader.rb'

class Dataset < ActiveRecord::Base
  belongs_to :user
  has_many :dataset_rows, dependent: :destroy, autosave: true
  has_and_belongs_to_many :runs

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

  def export(path)
    require 'csv'
    CSV.open(path, "wb") do |csv|
      csv << DatasetRow.export_header
      dataset_rows.each do |row|
        csv << row.export
      end
    end
  end

  def as_json(options={})
    options = {
      :only => [:id, :kind, :original_filename, :created_at],
      :methods => [:row_count]
    }.merge(options)
    super(options)
  end

end
