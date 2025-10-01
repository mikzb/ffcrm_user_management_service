# frozen_string_literal: true

require 'openssl'

module Jwt
  module Config
    module_function

    def issuer
      ENV['JWT_ISSUER'] || Rails.application.credentials.dig(:jwt, :issuer) || 'ffcrm-user-svc'
    end

    def audience
      ENV['JWT_AUDIENCE'] || Rails.application.credentials.dig(:jwt, :audience)
    end

    def kid
      ENV['JWT_KID'] || Rails.application.credentials.dig(:jwt, :kid) || 'default-kid'
    end

    def private_key_pem
      ENV['JWT_PRIVATE_KEY_PEM'] || Rails.application.credentials.dig(:jwt, :private_key_pem)
    end

    def public_key_pem
      ENV['JWT_PUBLIC_KEY_PEM'] || Rails.application.credentials.dig(:jwt, :public_key_pem)
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new(private_key_pem) if private_key_pem.present?
    end

    def public_key
      @public_key ||= OpenSSL::PKey::RSA.new(public_key_pem) if public_key_pem.present?
    end

    def algorithm
      'RS256'
    end

    def default_ttl_seconds
      (ENV['JWT_EXP']&.to_i).presence || 1800 # 30 minutes
    end

    def leeway
      10
    end
  end

  class Encoder
    def self.call(sub:, admin:, exp: nil, extra: {})
      key = Config.private_key
      raise ArgumentError, 'missing private key' unless key

      now = Time.now.to_i
      payload = {
        sub: sub.to_s,
        admin: !!admin,
        iat: now,
        iss: Config.issuer,
        exp: (exp || (now + Config.default_ttl_seconds))
      }
      payload[:aud] = Config.audience if Config.audience.present?
      payload.merge!(extra) if extra.present?

      headers = { kid: Config.kid, typ: 'JWT', alg: Config.algorithm }
      JWT.encode(payload, key, Config.algorithm, headers)
    end
  end

  class Decoder
    def self.call(token)
      raise ArgumentError, 'missing token' if token.blank?
      public_key = Config.public_key
      raise ArgumentError, 'missing public key' unless public_key

      options = {
        algorithm: Config.algorithm,
        iss: Config.issuer,
        verify_iss: true,
        leeway: Config.leeway
      }
      if Config.audience.present?
        options[:aud] = Config.audience
        options[:verify_aud] = true
      end

      decoded, = JWT.decode(token, public_key, true, options)
      decoded.symbolize_keys
    rescue JWT::ExpiredSignature
      raise :jwt_expired
    rescue JWT::DecodeError
      raise :jwt_invalid
    end
  end

  # JSON Web Key Set (JWKS) exposure for other services
  module Jwks
    module_function

    def current_keys
      pub = Config.public_key
      raise 'missing public key' unless pub

      n = Base64.urlsafe_encode64(pub.n.to_s(2), padding: false)
      e = Base64.urlsafe_encode64(pub.e.to_s(2), padding: false)

      [{
         kty: 'RSA',
         use: 'sig',
         kid: Config.kid,
         alg: Config.algorithm,
         n: n,
         e: e
       }]
    end

    def as_json
      { keys: current_keys }
    end
  end
end