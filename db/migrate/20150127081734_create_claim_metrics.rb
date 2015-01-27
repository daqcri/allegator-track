class CreateClaimMetrics < ActiveRecord::Migration
  def change
    create_table :claim_metrics, id: false do |t|
      t.references :run, index: true
      t.integer :claim_id
      t.float :cv
      t.float :ts
      t.float :min_ts
      t.float :max_ts
      t.float :number_supp_sources
      t.float :number_opp_sources
      t.float :total_sources
      t.float :number_distinct_value
      t.float :cv_global
      t.float :local_confidence_comparison
      t.float :ts_global
      t.float :ts_local
      t.boolean :label
    end
    add_index :claim_metrics, [:run_id, :claim_id], unique: true
  end
end
