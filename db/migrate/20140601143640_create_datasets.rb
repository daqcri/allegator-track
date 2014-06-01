class CreateDatasets < ActiveRecord::Migration
  def change
    create_table :datasets do |t|
      t.references :user, index: true
      t.column :upload, :oid
      t.string :kind
      t.string :original_filename

      t.timestamps
    end
  end
end
