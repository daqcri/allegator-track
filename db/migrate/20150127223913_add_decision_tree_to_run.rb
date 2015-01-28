class AddDecisionTreeToRun < ActiveRecord::Migration
  def change
    add_column :runs, :decision_tree, :text
  end
end
