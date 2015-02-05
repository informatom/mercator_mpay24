module MercatorMpay24
  class Admin::PaymentsController < ::Admin::AdminSiteController

    def self.model
      MercatorMPay24::Payment
    end

    def self.model_name
      mercator_mpay24_payment
    end

    def check_confirmation
      @payment = Payment.find(params[:id])
      @payment.check_transaction_status

      redirect_to ("/admin/orders/" + @payment.order.id.to_s)
    end
  end
end