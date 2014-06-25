class CreateSourceResults < ActiveRecord::Migration
  def change
    create_table :source_results do |t|
      t.references :run, index: true
      t.string :source_id, index: true
      t.float :trustworthiness, index: true
    end
  end
end
