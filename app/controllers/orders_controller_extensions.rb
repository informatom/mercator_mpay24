module OrdersControllerExtensions
  extend ActiveSupport::Concern

  included do
    def payment
      begin
        mpay24_response = MercatorMpay24::Gateway.new(merchant_id: Constant.find_by_key("mpay24_merchant_id").value,
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

    # Implements the test request from the MPay24 SOAP Specification Handbook, page 54
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