class AddAllegationFields < ActiveRecord::Migration
  def change
    add_column :datasets, :allegated_by_run_id, :integer
    add_column :runs, :allegates_run_id, :integer, index: true
    add_column :runs, :allegates_claim_id, :integer, index: true
    add_column :runs, :allegates_value, :float
  end
end
