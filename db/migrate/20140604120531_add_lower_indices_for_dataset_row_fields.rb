class AddLowerIndicesForDatasetRowFields < ActiveRecord::Migration
  def up
    %w(claim_id object_id property_key propery_value source_id timestamp).each do |column|
      ActiveRecord::Base.connection.execute("CREATE INDEX idx_dataset_rows_#{column} ON dataset_rows (LOWER(#{column}) varchar_pattern_ops)")
    end
  end

  def down
    %w(claim_id object_id property_key propery_value source_id timestamp).each do |column|
      ActiveRecord::Base.connection.execute("DROP INDEX idx_dataset_rows_#{column}")
    end
  end
end
