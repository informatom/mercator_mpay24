module MercatorMpay24
  class ConfirmationsController < ApplicationController

    skip_before_filter :set_locale
    skip_before_filter :auto_log_in
    skip_before_filter :remember_uri

    # Example requests:
    # http://devweb:3000/mercator_mpay24/confirmation?OPERATION=CONFIRMATION&TID=42&STATUS=ERROR&PRICE=35760&CURRENCY=EUR&P_TYPE=CC&BRAND=VISA&MPAYTID=1789332&USER_FIELD=&ORDERDESC=Warenkorb+vom+Di%2C+3%2EFeb+15%2C+10%3A56&CUSTOMER=42&CUSTOMER_EMAIL=&LANGUAGE=DE&CUSTOMER_ID=&PROFILE_ID=&PROFILE_STATUS=IGNORED&FILTER_STATUS=&APPR_CODE=%2Dtest%2D
    # http://devweb:3000/mercator_mpay24/confirmation?OPERATION=CONFIRMATION&TID=42&STATUS=BILLED&PRICE=35760&CURRENCY=EUR&P_TYPE=CC&BRAND=VISA&MPAYTID=1789332&USER_FIELD=&ORDERDESC=Warenkorb+vom+Di%2C+3%2EFeb+15%2C+10%3A56&CUSTOMER=42&CUSTOMER_EMAIL=&LANGUAGE=DE&CUSTOMER_ID=&PROFILE_ID=&PROFILE_STATUS=IGNORED&FILTER_STATUS=&APPR_CODE=%2Dtest%2D
    # stati ERROR, RESERVED, BILLED, REVERSED, CREDITED, SUSPENDED

    def create
      # IP -Adress-Restriction: [locale requests, MPay24 productive system, MPay24 test system]
      unless ["127.0.0.1", "213.164.25.245", "2143.164.23.169"].include?(request.ip)
        raise "Request to payment gateway from illegal address: " + request.ip
      end

      @confirmation = Confirmation.create(operation:      params[:OPERATION],
                                   tid:            params[:TID],
                                   status:         params[:STATUS],
                                   price:          params[:PRICE],
                                   currency:       params[:CURRENCY],
                                   p_type:         params[:P_TYPE],
                                   brand:          params[:BRAND],
                                   mpaytid:        params[:MPAYTID],
                                   user_field:     params[:USER_FIELD],
                                   orderdesc:      params[:ORDERDESC],
                                   customer:       params[:CUSTOMER],
                                   customer_email: params[:CUSTOMER_EMAIL],
                                   language:       params[:LANGUAGE],
                                   customer_id:    params[:CUSTOMER_ID],
                                   profile_id:     params[:PROFILE_ID],
                                   profile_status: params[:PROFILE_STATUS],
                                   filter_status:  params[:FILTER_STATUS],
                                   appr_code:      params[:APPR_CODE],
                                   payment_id:     params[:TID])
      @order = @confirmation.payment.order

      case @confirmation.status
        when *["ERROR", "REVERSED", "CREDITED"]
          @order.lifecycle.failing_payment!(User.find_by(surname: "MPay24"))
        when *["RESERVED", "SUSPENDED"]
          nil
        when "BILLED"
          @order.lifecycle.successful_payment!(User.find_by(surname: "MPay24"))
          if Rails.application.config.try(:erp) == "mesonic" && Rails.env == "production"
            # A quick ckeck, if erp_account_number is current
            # (User could have been changed since last job run)
            @order.user.update_erp_account_nr()

            @order.push_to_mesonic()
          end
      end

      render nothing: true
    end

    private

    def logged_in?
      false
    end
  end
end