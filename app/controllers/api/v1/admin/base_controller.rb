# app/controllers/api/v1/admin/base_controller.rb
class Api::V1::Admin::BaseController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  private

  def require_admin!
    unless @current_jwt_claims&.dig(:admin) && current_user&.admin?
      render json: { error: 'forbidden' }, status: :forbidden
    end
  end
end