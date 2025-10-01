# frozen_string_literal: true

class Api::V1::Admin::TokensController < ApplicationController
  # POST /api/v1/admin/tokens
  # body: { email: "...", password: "..." }
  def create
    user = User.find_for_database_authentication(email: params[:email].to_s)
    return render json: { error: 'invalid_credentials' }, status: :unauthorized unless user&.valid_password?(params[:password])

    token = Jwt::Encoder.call(sub: user.id, admin: user.admin)
    render json: { token: token, token_type: 'Bearer', expires_in: Jwt::Config.default_ttl_seconds }
  end
end