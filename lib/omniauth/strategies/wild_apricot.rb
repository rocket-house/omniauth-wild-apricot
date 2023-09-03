# frozen_string_literal: true

require 'oauth2'
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class WildApricot < OmniAuth::Strategies::OAuth2

      DEFAULT_SCOPE = 'contacts_me'
      AUTHORIZE_URL = '/sys/login/OAuthLogin'
      BASE_API_URL  = 'https://api.wildapricot.org/v2'
      TOKEN_URL     = 'https://oauth.wildapricot.org/auth/token'

      option :name, 'wild_apricot'

      def authorize_params
        super.merge({
          scope: DEFAULT_SCOPE,
          response_type: 'authorization_code',
          claimed_account_id: options.account_num
        })
      end

      def token_params
        super.merge({
          scope: DEFAULT_SCOPE,
          headers: {
            'Authorization' => "Basic #{authorization_header}"
          },
        })
      end

      def client_options
        {
          site: options.site,
          authorize_url: AUTHORIZE_URL,
          token_url: TOKEN_URL
        }
      end

      def client
        ::OAuth2::Client.new(options.client_id, options.client_secret, deep_symbolize(client_options))
      end

      uid { raw_info['Id'].to_s }

      info do
        {
          email: raw_info['Email'],
          first_name: raw_info['FirstName'],
          last_name: raw_info['LastName'],
          name: "#{raw_info['FirstName']} #{raw_info['LastName']}"
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get(contact_url).parsed
      end

      def callback_url
        full_host + script_name + callback_path
      end

      private

      def contact_url
        "#{BASE_API_URL}/Accounts/#{options.account_num}/Contacts/Me"
      end

      def authorization_header
        Base64.strict_encode64("#{options.client_id}:#{options.client_secret}")
      end

    end
  end
end
