class SimplifiedUser < ActiveRecord::Base
  self.table_name = 'users'

  # Add the methods your API needs
  scope :text_search, lambda { |query|
    query = query.gsub(/[^\w\s\-\.'\p{L}]/u, '').strip
    where('upper(username) LIKE upper(:s) OR upper(email) LIKE upper(:s) OR upper(first_name) LIKE upper(:s) OR upper(last_name) LIKE upper(:s)', s: "%#{query}%")
  }

  def full_name
    first_name.blank? && last_name.blank? ? email : "#{first_name} #{last_name}".strip
  end

  def name
    first_name.blank? ? username : first_name
  end
end

# Then update your controller to use SimplifiedUser:
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
    users = SimplifiedUser.text_search(query).limit(10).order(:first_name, :last_name)

    results = users.map do |user|
      "#{user.full_name} (@#{user.username})"
    end

    render json: results
  end

  private

  def set_user
    @user = SimplifiedUser.find(params[:id])
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