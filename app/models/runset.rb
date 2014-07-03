class Runset < ActiveRecord::Base
  belongs_to :user
  has_many :runs
  has_and_belongs_to_many :datasets

  def as_json(options={})
    options = {
      :only => [:id, :created_at]
    }.merge(options)
    super(options)
  end

end
