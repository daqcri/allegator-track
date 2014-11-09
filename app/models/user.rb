class User < ActiveRecord::Base
   before_save :ensure_authentication_token
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :datasets
  has_many :dataset_rows, through: :datasets
  has_many :runsets
  has_many :runs, through: :runsets
  
  def to_s
    email
  end

  def ensure_authentication_token
  	if authentication_token.blank?
		self.authentication_token = generate_authentication_token
  	end
  end
	 
  private

  def generate_authentication_token
	loop do
		token = Devise.friendly_token
		break token unless User.where(authentication_token: token).first
	end
  end
end
