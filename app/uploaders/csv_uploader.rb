# encoding: utf-8

class CsvUploader < CarrierWave::Uploader::Base

  storage :postgresql_lo

  # Add a white list of extensions which are allowed to be uploaded.
  def extension_white_list
    %w(csv txt)
  end

end
