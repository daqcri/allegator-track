class RenameDatasetRowsObjectId < ActiveRecord::Migration
  def change
    rename_column :dataset_rows, :object_id, :object_key
  end
end
