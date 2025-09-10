class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :change_password, :preferences, :avatar]

  def show
    render json: UserSerializer.new(@user).serializable_hash
  end

  def update
    if @user.update(user_params)
      render json: {
        user: UserSerializer.new(@user).serializable_hash,
        message: 'User updated successfully'
      }
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end

  def auto_complete
    query = params[:term] || ''
    users = User.text_search(query).limit(10).order(:first_name, :last_name)

    results = users.map do |user|
      "#{user.full_name} (@#{user.username})"
    end

    render json: results
  end

  # New: PUT /api/v1/users/:id/change_password
  def change_password
    current_password = params[:current_password]
    new_password = params[:password]
    new_password_confirmation = params[:password_confirmation]

    unless @user.valid_password?(current_password)
      return render json: { status: 'error', errors: { current_password: [I18n.t(:msg_invalid_password)] } }, status: :unprocessable_entity
    end

    if new_password.blank?
      return render json: { status: 'noop', message: I18n.t(:msg_password_not_changed) }
    end

    @user.password = new_password
    @user.password_confirmation = new_password_confirmation

    if @user.save
      render json: { status: 'ok', message: I18n.t(:msg_password_changed) }
    else
      render json: { status: 'error', errors: @user.errors }, status: :unprocessable_entity
    end
  end

  # New: PUT /api/v1/users/:id/preferences
  def preferences
    locale = params.dig(:preference, :locale) || params[:locale]
    @user.preference[:locale] = locale
    render json: { status: 'ok' }
  end

  # New:
  # - PUT  /api/v1/users/:id/avatar with { gravatar: true } to switch to gravatar
  # - POST /api/v1/users/:id/avatar multipart with avatar[file] or avatar[image]
  def avatar
    if ActiveModel::Type::Boolean.new.cast(params[:gravatar])
      @user.avatar = nil
      @user.save
      return render json: { status: 'ok' }
    end

    file = params.dig(:avatar, :image) || params.dig(:avatar, :file) || params[:file]
    unless file
      return render json: { status: 'noop' }
    end

    avatar = Avatar.create(image: file, entity: @user, user_id: @user.id)
    if avatar.valid?
      @user.avatar = avatar
      @user.save
      render json: { status: 'ok' }
    else
      render json: { status: 'error', errors: { image: [I18n.t(:msg_bad_image_file)] } }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def user_params
    params.require(:user).permit(
      :username, :email, :first_name, :last_name, :title,
      :company, :alt_email, :phone, :mobile, :aim, :yahoo,
      :google, :skype
    )
  end
end