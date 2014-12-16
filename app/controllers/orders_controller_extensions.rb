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

    def test_payment
        mpay24_response = MercatorMpay24::Gateway.new(merchant_id: Constant.find_by_key("mpay24_merchant_test_id").value,
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
  end
end