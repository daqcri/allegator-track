class CreateClaimResults < ActiveRecord::Migration
  def change
    create_table :claim_results do |t|
      t.references :run, index: true
      t.string :claim_id, index: true
      t.float :confidence, index: true
      t.boolean :is_true, index: true
    end
  end
end
