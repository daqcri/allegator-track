class RemoveClaimIdFromDatasetRows < ActiveRecord::Migration
  def up
    remove_column :dataset_rows, :claim_id
    remove_column :claim_results, :claim_id
    add_column :claim_results, :claim_id, :integer
    add_index :claim_results, :claim_id
  end

  def down
    remove_column :claim_results, :claim_id
    add_column :claim_results, :claim_id, :string, index: true
    add_column :dataset_rows, :claim_id, :string
    ActiveRecord::Base.connection.execute("CREATE INDEX idx_dataset_rows_claim_id ON dataset_rows (LOWER(claim_id) varchar_pattern_ops)")
  end
end
