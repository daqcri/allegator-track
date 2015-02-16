class AddHasGuiAccessToUser < ActiveRecord::Migration
  def change
    add_column :users, :has_gui_access, :boolean, default: false
  end
end
