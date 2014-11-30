ActiveAdmin.register ClaimResult do

  index do
    selectable_column
    id_column
    column :confidence
    column :normalized
    column :is_true
    column :claim do |claim_result|
      link_to claim_result.claim_id, admin_dataset_row_path(claim_result.claim_id)
    end
    actions
  end

end
