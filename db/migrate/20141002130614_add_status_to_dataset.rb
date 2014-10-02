class AddStatusToDataset < ActiveRecord::Migration
  def up
    add_column :datasets, :status, :string
    ActiveRecord::Base.connection.execute "UPDATE datasets set status='done';"
  end

  def down
    remove_column :datasets, :status
  end
end
