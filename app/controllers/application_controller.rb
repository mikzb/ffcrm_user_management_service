class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end

  def bearer_token
    hdr = request.headers['Authorization'].to_s
    return nil unless hdr.start_with?('Bearer ')
    hdr.split(' ', 2).last
  end

  def authenticate!
    token = bearer_token
    return render json: { error: 'unauthorized' }, status: :unauthorized if token.blank?

    begin
      claims = Jwt::Decoder.call(token)
    rescue => e
      return render json: { error: 'token_expired' }, status: :unauthorized if e == :jwt_expired
      return render json: { error: 'unauthorized' }, status: :unauthorized
    end

    @current_jwt_claims = claims
    @current_user = User.find_by(id: claims[:sub])
    render json: { error: 'unauthorized' }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end