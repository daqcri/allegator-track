class AddS3KeyToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :s3_key, :string, :limit => 1024
  end
end
