class RenameColumnTypo < ActiveRecord::Migration
  def change
    rename_column :dataset_rows, :propery_value, :property_value
  end
end
