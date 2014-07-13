class AddBucketIdToClaimResult < ActiveRecord::Migration
  def change
    add_column :claim_results, :bucket_id, :integer
    add_index :claim_results, :bucket_id
  end
end
