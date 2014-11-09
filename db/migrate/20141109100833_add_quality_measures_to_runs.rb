class AddQualityMeasuresToRuns < ActiveRecord::Migration
  def change
    %w(precision accuracy recall specificity).each do |metric|
      add_column :runs, metric.to_sym, :float
    end
    add_column :runs, :iterations, :integer
  end
end
