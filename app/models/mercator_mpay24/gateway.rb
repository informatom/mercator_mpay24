require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'active_support'

module MercatorMPay24
  class Gateway
    GATEWAY_URL = "www.mpay24.com"
    ETPV5_PATH = '/app/bin/etpv5'
    HEADERS =  {"Referer" => "http://" + Constant.find_by_key("shop_domain").value,
                "Content-Type"=>"application/x-www-form-urlencoded"}
    ETPV5_DATA = {'OPERATION' => 'SELECTPAYMENT'}

    class GatewayError < Exception
    end

    def initialize(merchant_id, tid, order_xml)
      @merchant_id = merchant_id
      @tid = tid
      @order_xml = order_xml
    end

    def data
      {'TID' => @tid, 'MDXI' => @order_xml, 'MERCHANTID' => @merchant_id }.merge( ETPV5_DATA )
    end

    def get_response
      http = Net::HTTP.new(GATEWAY_URL, 443)
      http.use_ssl = true
      response, body = http.post(ETPV5_PATH, data.to_query, HEADERS)

      body_params = CGI.parse(body)
      if body_params['STATUS'] == ['ERROR']
        raise Mpay24Gateway::GatewayError, [body_params['RETURNCODE'], body_params['EXTERNALERROR']].join(" : ")
      end
      body_params
    end
  end
end