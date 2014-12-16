require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'

module MercatorMpay24
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

    # Test using MercatorMpay24::Gateway.soap_test_connection()
    # Implements the test request from the MPay24 SOAP Specification Handbook, page 54
    def self.soap_test_connection
      client = Savon.client(basic_auth: ["u" + Constant.find_by_key("mpay_test_username").value,
                                         Constant.find_by_key("mpay_test_password").value ],
                            wsdl:       "https://test.mpay24.com/soap/etp/1.5/ETP.wsdl",
                            endpoint:   "https://test.mpay24.com/app/bin/etpproxy_v15",
                            logger:     Rails.logger,
                            log_level:  :info,
                            log:        true,
                            pretty_print_xml: true)

      response = client.call(:select_payment,
                              message: {merchantID: Constant.find_by_key("mpay_test_username").value,
                                        mdxi: {"Order" => {"Tid" => "cust9126", "Price" => "10.00"}}})

      puts "The following line should be an url like: https://test.mpay24.com/app/bin/checkout/payment/%SOMEID%"

      if response.body[:select_payment_response]
        puts response.body[:select_payment_response][:location]
      else
        puts "Error: Response is not of the expected format."
      end
    end
  end
end