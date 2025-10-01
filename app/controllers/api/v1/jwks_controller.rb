# frozen_string_literal: true

class Api::V1::JwksController < ActionController::API
  def show
    render json: Jwt::Jwks.as_json
  end
end