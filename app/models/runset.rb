class Runset < ActiveRecord::Base
  belongs_to :user
  has_many :runs, dependent: :destroy
  has_and_belongs_to_many :datasets

  def as_json(options={})
    options = {
      :only => [:id, :created_at],
      :include => {
        :runs => {
          :only => [:id, :algorithm, :created_at],
          :methods => [:display, :status, :duration]
        }
      }
    }.merge(options)
    super(options)
  end

end
