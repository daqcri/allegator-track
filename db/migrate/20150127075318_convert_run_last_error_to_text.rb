class ConvertRunLastErrorToText < ActiveRecord::Migration
  def change
    change_column :runs, :last_error, :text
  end
end
