ActiveAdmin.register Delayed::Job, as: 'Delayed Job' do

  filter :id
  filter :queue#, as: :select, collection: %w(default)
  filter :handler
  filter :last_error
  filter :created_at
  filter :updated_at
  filter :run_at
  filter :locked_at
  filter :locked_by
  filter :failed_at

  batch_action :unlock do |selection|
    Delayed::Job.find(selection).each do |job|
      job.unlock
      job.save
    end
    redirect_to admin_delayed_jobs_path, notice: 'Jobs unlocked successfully'
  end

  index do
    selectable_column
    column :id do |job|
      link_to job.id, admin_delayed_job_path(job)
    end
    column :queue
    column :handler do |job|
      "<pre>#{job.handler}</pre>".html_safe
    end
    column :last_error do |job|
      truncate job.last_error.split(/\n/).first, length: 1024 rescue ""
    end
    column :created_at
    column :updated_at
    column :run_at
    column :locked_at
    column :locked_by
    column :failed_at
    column :attempts

    actions
  end

  show do |job|
    attributes_table do 
      row :id
      row :attempts
      row :handler do
        "<pre>#{job.handler}</pre>".html_safe
      end
      row :last_error do
        "<pre>#{job.last_error}</pre>".html_safe
      end
      row :run_at
      row :locked_at
      row :failed_at
      row :locked_by
      row :queue
      row :created_at
      row :updated_at
    end
  end
end
