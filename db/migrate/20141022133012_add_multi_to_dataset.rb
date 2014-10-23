class AddMultiToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :multi, :boolean, default: false
    add_column :dataset_rows, :parent_id, :integer, index: true
  end
end
