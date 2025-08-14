class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [:show, :update]

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
    # Use the correct model class (User, not Users::User)
    users = User.text_search(query).limit(10).order(:first_name, :last_name)

    results = users.map do |user|
      "#{user.full_name} (@#{user.username})"
    end

    render json: results
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