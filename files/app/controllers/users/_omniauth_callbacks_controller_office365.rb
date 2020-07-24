
  def office365
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    puts request.env["omniauth.auth"]
  
    @user = User.find_for_office365_oauth(request.env["omniauth.auth"], current_user, session)
  
    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      if @user.errors.empty?
        set_flash_message(:notice, :success, :kind => "office365") if is_navigational_format?
      else
        set_flash_message(:error, @user.errors[:base].first) if is_navigational_format?
      end
    else
      session["devise.office365_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end
