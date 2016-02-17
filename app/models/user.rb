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

  after_create :send_admin_new_user_mail
 
  def to_s
    email
  end

  def ensure_authentication_token
		self.authentication_token = generate_authentication_token if authentication_token.blank?
  end

  def self.create_guest_user!
    user = User.create :email => guest_email,
      :password => 'vyC4Jb8t,-kI', :password_confirmation => 'vyC4Jb8t,-kI'

    user.confirm!
    user
  end

  def self.destroy_guest_user!
    guest.destroy
  end

  def self.guest_email
    'guest@example.com'
  end

  def self.guest
    User.find_by_email(guest_email)
  end

  def guest?
    User.guest?(self.email)
  end

  def self.guest?(email)
    email == guest_email
  end
	 
private

  def generate_authentication_token
  	loop do
  		token = Devise.friendly_token
  		break token unless User.where(authentication_token: token).first
  	end
  end

  def send_admin_new_user_mail
    UserMailer.new_user_registration(self).deliver
  end
  handle_asynchronously :send_admin_new_user_mail

end
