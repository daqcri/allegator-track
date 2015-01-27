class AddFeatureScoresToRun < ActiveRecord::Migration
  def change
    add_column :runs, :feature_scores, :text
  end
end
