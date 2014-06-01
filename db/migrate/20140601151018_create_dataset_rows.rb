class CreateDatasetRows < ActiveRecord::Migration
  def change
    create_table :dataset_rows do |t|
      t.references :dataset, index: true

      t.string :claim_id, index: true
      t.string :object_id, index: true
      t.string :property_key, index: true
      t.string :propery_value, index: true
      t.string :source_id, index: true
      t.string :timestamp, index: true
    end
  end
end
