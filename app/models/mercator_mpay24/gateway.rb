require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'

module MercatorMPay24
  class Gateway
    class GatewayError < Exception
    end

    def initialize(merchant_id: nil, tid: nil , order_xml: nil)
      @merchant_id = merchant_id
      @tid = tid
      @order_xml = order_xml
    end

    def data
      {'TID' => @tid, 'MDXI' => @order_xml, 'MERCHANTID' => @merchant_id }.merge({'OPERATION' => 'SELECTPAYMENT'})
    end

    def get_response
      http = Net::HTTP.new("www.mpay24.com", 443)
      http.use_ssl = true
      response, body = http.post('/app/bin/etpv5', data.to_query,
                                 {"Referer" => "http://" + Constant.find_by_key("shop_domain").value,
                                  "Content-Type"=>"application/x-www-form-urlencoded"})

      body_params = CGI.parse(body)

      if body_params['STATUS'] == ['ERROR']
        raise Mpay24Gateway::GatewayError, [body_params['RETURNCODE'], body_params['EXTERNALERROR']].join(" : ")
      end

      body_params
    end
  end
end