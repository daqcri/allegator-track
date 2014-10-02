class RemoveOidFromDataset < ActiveRecord::Migration
  def up
    remove_column :datasets, :upload
  end

  def down
    add_column :datasets, :upload, :oid
  end
end
