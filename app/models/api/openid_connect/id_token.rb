require "uri"

module Api
  module OpenidConnect
    class IdToken < ActiveRecord::Base
      belongs_to :authorization

      before_validation :setup, on: :create

      default_scope { where("expires_at >= ?", Time.zone.now.utc) }

      def setup
        self.expires_at = 30.minutes.from_now
      end

      def to_jwt(options={})
        to_response_object(options).to_jwt OpenidConnect::IdTokenConfig::PRIVATE_KEY
      end

      def to_response_object(options={})
        OpenIDConnect::ResponseObject::IdToken.new(claims).tap do |id_token|
          id_token.code = options[:code] if options[:code]
          id_token.access_token = options[:access_token] if options[:access_token]
        end
      end

      def claims
        sub = build_sub
        @claims ||= {
          iss:       AppConfig.environment.url,
          sub:       sub,
          aud:       authorization.o_auth_application.client_id,
          exp:       expires_at.to_i,
          iat:       created_at.to_i,
          auth_time: authorization.user.current_sign_in_at.to_i,
          nonce:     nonce,
          acr:       0
        }
      end

      def build_sub
        Api::OpenidConnect::SubjectIdentifierCreator.createSub(authorization)
      end
    end
  end
end
