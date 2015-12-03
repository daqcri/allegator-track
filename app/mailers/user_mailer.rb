class UserMailer < ActionMailer::Base
  default from: Devise.mailer_sender

  def new_user_registration(user)
    @user = user
    send_admins do |admins|
      mail(to: admins, subject: 'New user registraion')
    end
  end

private

  def send_admins
    admins = AdminUser.pluck(:email)
    if admins.length > 0
      yield admins if block_given?
    else
      logger.warn "WARNING: No admins found to receive emails" 
    end
  end

end