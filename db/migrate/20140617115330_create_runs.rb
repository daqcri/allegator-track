class CreateRuns < ActiveRecord::Migration
  def change
    create_table :runs do |t|
      t.string :algorithm
      t.string :general_config
      t.string :config
      t.references :user

      t.timestamps
    end

    create_table :datasets_runs, :id => false do |t|
      t.references :dataset
      t.references :run
    end
  end
end
