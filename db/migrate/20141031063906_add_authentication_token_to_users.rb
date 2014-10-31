class AddAuthenticationTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :authetication_token, :string
  end
end
