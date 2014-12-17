module OrdersControllerExtensions
  extend ActiveSupport::Concern

  included do
    def payment
      begin
        mpay24_response = MercatorMpay24::Gateway.new(merchant_id: Constant.find_by_key("mpay_test_username").value,
                                                      tid: self.this.erp_order_number,
                                                      order_xml: self.this.to_mpay24_xml)
                                                 .get_response
        @wmbi_url = mpay24_response['LOCATION'].try(:first)
        render :action => :payment
      rescue Exception => e
        puts "MPAY24 EXCEPTION : #{e}"
        render :action => :payment_error
      end
    end

    def test_payment
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
                                        mdxi: {"Order" => {"Tid" => "0815/4711", "Price" => "12.34"}}})

      if response.body[:select_payment_response]
        redirect_to response.body[:select_payment_response][:location]
      else
        puts "Error: Response is not of the expected format."
      end
    end
  end
end