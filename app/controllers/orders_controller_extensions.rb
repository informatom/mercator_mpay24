module OrdersControllerExtensions
  extend ActiveSupport::Concern

  included do
    def payment
      begin
        cart_xml = @cart.to_mpay24_xml(order_id: self.this.erp_order_number,customer: self.this.user)
        mpay24_response = MercatorMpay24::Gateway.new( IvellioVellin.mpay24_merchant_id, self.this.erp_order_number, cart_xml )
                                       .get_response
        # @wmbi_url = "https://test.mPAY24.com/app/bin/checkout/payment/f5c4fac03f524881a0b5fc1f8ff03063\n"
        @wmbi_url = mpay24_response['LOCATION'].try(:first)

        render :action => :payment

      rescue Exception => e
        puts "MPAY24 EXCEPTION : #{e}"
        render :action => :payment_error
      end
    end
  end
end