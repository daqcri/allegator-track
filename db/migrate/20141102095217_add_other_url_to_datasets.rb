class AddOtherUrlToDatasets < ActiveRecord::Migration
  def change
    add_column :datasets, :other_url, :string
  end
end
