ActiveAdmin.register User do

  filter :email
  
  permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  form do |f|
    f.inputs "User Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  action_item :only => [:edit, :show] do 
    link_to "Login as", login_as_admin_user_path(User.find params[:id]), :method => :get, :target => '_blank'
  end

  action_item :only => [:edit, :show] do 
    button_to "Confirm", confirm_admin_user_path(User.find params[:id]), :method => :put
  end

  # login as users
  member_action :login_as, :method => :get do
    user = User.find(params[:id])
    sign_in(user, bypass: true)
    redirect_to root_path 
  end

  # confirm users
  member_action :confirm, :method => :put do
    user = User.find params[:id]
    user.confirm!
    redirect_to admin_user_path(user), notice: "User confirmed successfully"
  end

end
