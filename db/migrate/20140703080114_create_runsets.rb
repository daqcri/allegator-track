class CreateRunsets < ActiveRecord::Migration
  def up
    create_table :runsets do |t|
      t.references :user, index: true
      t.timestamps
    end

    add_column :runs, :runset_id, :integer
    add_index :runs, :runset_id
    remove_column :runs, :user_id

    create_table :datasets_runsets, :id => false do |t|
      t.references :dataset, index: true
      t.references :runset, index: true
    end

  end

  def down
    drop_table :datasets_runsets
    add_column :runs, :user_id, :integer, index: true
    add_index :runs, :user_id
    remove_column :runs, :runset_id
    drop_table :runsets
  end

end
