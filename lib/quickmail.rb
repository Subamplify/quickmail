# frozen_string_literal: true

require 'rest-client'

require 'quickmail/authentication'
require 'quickmail/inventory'
require 'quickmail/order'
require 'quickmail/tracking'

module Quickmail

  class QuickmailError < StandardError
  end

  class AuthenticationError < QuickmailError; end

  class ConfigurationError < QuickmailError; end

  class ApiRequestError < QuickmailError
    attr_reader :response_code, :response_headers, :response_body

    def initialize(response_code:, response_headers:, response_body:)
      @response_code = response_code
      @response_headers = response_headers
      @response_body = response_body
    end
  end

  class << self

    attr_writer :access_token, :api_version, :test_mode, :api_base

    def access_token
      defined? @access_token and @access_token or raise(
        ConfigurationError, "Quickmail access token not configured"
      )
    end

    def api_version
      defined? @api_version and @api_version or raise(
        ConfigurationError, "Quickmail api version not configured"
      )
    end

    def test_mode
      @test_mode.nil? ? false : @test_mode
    end

    def api_base
      Quickmail.test_mode ? "https://getquickmail.com/api/test/" : "https://getquickmail.com/api/"
    end

    def request(method, resource, params = {}, access_token = nil)
      ss_access_token = access_token || Quickmail.access_token
      ss_api_version = Quickmail.api_version

      defined? method or raise(
        ArgumentError, "Request method has not been specified"
      )
      defined? resource or raise(
        ArgumentError, "Request resource has not been specified"
      )
      if method == :get
        url = Quickmail.api_base + ss_api_version + '/' + resource + '?' + params
        payload = nil
        headers = {accept: :json, content_type: :json, Authorization: "Bearer #{ss_access_token}"}
      else
        url = Quickmail.api_base + ss_api_version + '/' + resource
        payload = params
        headers = {accept: :json, content_type: :json, Authorization: "Bearer #{ss_access_token}"}
      end
      RestClient::Request.new({
                                method: method,
                                url: url,
                                payload: payload.to_json,
                                headers: headers
                              }).execute do |response, request, result|
          str_response = response.to_str
          str_response.blank? ? '' : JSON.parse(str_response)
      end
    end

    def datetime_format(datetime)
      datetime.strftime("%Y-%m-%d %T")
    end
  end
end
