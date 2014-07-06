class AddNormalizedToResults < ActiveRecord::Migration
  def change
    add_column :source_results, :normalized, :float
    add_column :claim_results, :normalized, :float

    add_index :source_results, :source_id
    add_index :source_results, :trustworthiness
    add_index :source_results, :normalized
    
    add_index :claim_results, :claim_id
    add_index :claim_results, :confidence
    add_index :claim_results, :normalized
  end
end
