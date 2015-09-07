class Admin::PaymentsController < ::Admin::AdminSiteController
  skip_before_filter :admin_required
  before_filter :sales_required

  def check_confirmation
    @payment = MercatorMpay24::Payment.find(params[:id])
    @payment.check_transaction_status

    redirect_to ("/admin/orders/" + @payment.order.id.to_s)
  end
end