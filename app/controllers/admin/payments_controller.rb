class Admin::PaymentsController < ::Admin::AdminSiteController

  def check_confirmation
    @payment = MercatorMpay24::Payment.find(params[:id])
    @payment.check_transaction_status

    redirect_to ("/admin/orders/" + @payment.order.id.to_s)
  end
end