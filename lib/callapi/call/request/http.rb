require 'net/http'
require 'addressable/uri'
require 'addressabler'

class Callapi::Call::Request::Http < Callapi::Call::Request::Base
  require_relative 'http/log_helper'

  include Callapi::Call::Request::Http::LogHelper

  HTTP_METHOD_TO_REQUEST_CLASS = {
    get:     Net::HTTP::Get,
    post:    Net::HTTP::Post,
    put:     Net::HTTP::Put,
    delete:  Net::HTTP::Delete,
    patch:   Net::HTTP::Patch
  }

  def response
    with_logging do
      http.use_ssl = true if use_ssl?
      http.request(request)
    end
  end

  private

  def host
    raise NotImplementedError
  end

  def http
    #TODO: Use HTTParty
    Net::HTTP.new(uri.host, uri.port)
  end

  def request
    request_class.new(uri.request_uri, headers).tap do |request|
      request.set_form_data params if put_params_in_request_body?
    end
  end

  def request_class
    HTTP_METHOD_TO_REQUEST_CLASS[request_method] || raise(Callapi::UnknownHttpMethodError)
  end

  def uri
    @uri ||= Addressable::URI.parse(host).tap do |uri|
      uri.path = request_path
      uri.query_hash = params unless put_params_in_request_body?
    end
  end

  def put_params_in_request_body?
    [:post, :patch, :put].include? request_method
  end
  
  def use_ssl?
    uri.scheme == 'https'
  end
end
