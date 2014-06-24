class AddStatusToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :started_at, :timestamp
    add_column :runs, :finished_at, :timestamp
  end
end
