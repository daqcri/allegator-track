ActiveAdmin.register Dataset do

  filter :user
  filter :kind, as: :select, collection: %w(ground claims)
  filter :original_filename
  filter :status, as: :select, collection: %w(processing done failed)

  index do
    selectable_column
    id_column
    column :kind
    column :original_filename
    column :created_at
    column :updated_at
    column :status
    column :s3_hosted do |dataset|
      !!dataset.other_url
    end
    actions
  end

end
