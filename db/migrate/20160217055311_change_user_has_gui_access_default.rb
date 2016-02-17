class ChangeUserHasGuiAccessDefault < ActiveRecord::Migration
  def up
    change_column_default :users, :has_gui_access, true
  end
  
  def down
    change_column_default :users, :has_gui_access, false
  end
end
