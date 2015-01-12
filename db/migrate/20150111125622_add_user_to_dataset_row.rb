class AddUserToDatasetRow < ActiveRecord::Migration
  def up
    # add a redundant column to be able to create a unique index
    add_column :dataset_rows, :user_id, :integer, null: false, default: 0
    # add default value for source & timestamp because NULL is not considered equal in postgres
    # these 2 fields could be null
    change_column :dataset_rows, :timestamp, :string, default: ''
    change_column :dataset_rows, :source_id, :string, default: ''
    # make 3 fields not null
    change_column :dataset_rows, :object_key, :string, null: false
    change_column :dataset_rows, :property_key, :string, null: false
    change_column :dataset_rows, :property_value, :string, null: false

    # add the unique constraint
    add_index :dataset_rows, [
      :object_key, :property_key, :property_value, :source_id, :timestamp, :user_id],
      unique: true, name: 'index_dataset_rows_on_all'
    # update all rows to have this redundant value
    ActiveRecord::Base.connection.execute "
      UPDATE dataset_rows
      SET user_id = datasets.user_id
      FROM datasets
      WHERE dataset_rows.dataset_id = datasets.id
    "
  end

  def down
    remove_index :dataset_rows, name: 'index_dataset_rows_on_all'
    change_column :dataset_rows, :object_key, :string, null: true
    change_column :dataset_rows, :property_key, :string, null: true
    change_column :dataset_rows, :property_value, :string, null: true
    change_column :dataset_rows, :timestamp, :string, default: nil
    change_column :dataset_rows, :source_id, :string, default: nil
    remove_column :dataset_rows, :user_id
  end
end
