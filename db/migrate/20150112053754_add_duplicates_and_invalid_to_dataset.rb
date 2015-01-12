class AddDuplicatesAndInvalidToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :duplicate_rows, :integer
    add_column :datasets, :invalid_rows, :integer
  end
end
