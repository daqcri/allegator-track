class AddLastErrorToRun < ActiveRecord::Migration
  def change
    add_column :runs, :last_error, :string
  end
end
