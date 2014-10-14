class AddIndexesToDatasetRows < ActiveRecord::Migration
  def change
    add_index :dataset_rows, :claim_id
    add_index :dataset_rows, :object_key 
    add_index :dataset_rows, :property_key 
    add_index :dataset_rows, :property_value
    add_index :dataset_rows, :source_id 
    add_index :dataset_rows, :timestamp
  end
end
