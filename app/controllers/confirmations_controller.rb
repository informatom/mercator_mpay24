class ConfirmationsController < ApplicationController

  skip_before_filter :set_locale
  skip_before_filter :auto_log_in
  skip_before_filter :remember_uri

  # Example requests:
  # http://devweb:3000/mercator_mpay24/confirmation?OPERATION=CONFIRMATION&TID=42&STATUS=ERROR&PRICE=35760&CURRENCY=EUR&P_TYPE=CC&BRAND=VISA&MPAYTID=1789332&USER_FIELD=&ORDERDESC=Warenkorb+vom+Di%2C+3%2EFeb+15%2C+10%3A56&CUSTOMER=42&CUSTOMER_EMAIL=&LANGUAGE=DE&CUSTOMER_ID=&PROFILE_ID=&PROFILE_STATUS=IGNORED&FILTER_STATUS=&APPR_CODE=%2Dtest%2D
  # http://devweb:3000/mercator_mpay24/confirmation?OPERATION=CONFIRMATION&TID=42&STATUS=BILLED&PRICE=35760&CURRENCY=EUR&P_TYPE=CC&BRAND=VISA&MPAYTID=1789332&USER_FIELD=&ORDERDESC=Warenkorb+vom+Di%2C+3%2EFeb+15%2C+10%3A56&CUSTOMER=42&CUSTOMER_EMAIL=&LANGUAGE=DE&CUSTOMER_ID=&PROFILE_ID=&PROFILE_STATUS=IGNORED&FILTER_STATUS=&APPR_CODE=%2Dtest%2D
  # stati ERROR, RESERVED, BILLED, REVERSED, CREDITED, SUSPENDED

  def create
    # IP -Adress-Restriction: [local requests, MPay24 productive system, MPay24 test system]
    request_ip = request.ip # to make testing easier

    unless (request_ip == "127.0.0.1" ||
            request_ip == "213.164.23.169" ||
            request_ip == "178.190.236.94" ||
            (request_ip >= "213.164.25.224" && request_ip <= "213.164.25.255") ||
            (request_ip >= "217.175.200.16" && request_ip <= "217.175.200.32"))
      raise "Request to payment gateway from illegal address: " + request_ip
    end

    @confirmation = MercatorMpay24::Confirmation.create(operation:      params[:OPERATION],
                                                        tid:            params[:TID],
                                                        status:         params[:STATUS],
                                                        price:          params[:PRICE],
                                                        currency:       params[:CURRENCY],
                                                        p_type:         params[:P_TYPE],
                                                        brand:          params[:BRAND],
                                                        mpaytid:        params[:MPAYTID],
                                                        user_field:     params[:USER_FIELD],
                                                        orderdesc:      params[:ORDERDESC].encode('utf-8', 'iso-8859-1'),
                                                        customer:       params[:CUSTOMER],
                                                        customer_email: params[:CUSTOMER_EMAIL],
                                                        language:       params[:LANGUAGE],
                                                        customer_id:    params[:CUSTOMER_ID],
                                                        profile_id:     params[:PROFILE_ID],
                                                        profile_status: params[:PROFILE_STATUS],
                                                        filter_status:  params[:FILTER_STATUS],
                                                        appr_code:      params[:APPR_CODE],
                                                        payment_id:     params[:TID])
    @confirmation.update_order
    render nothing: true
  end

  private

  def logged_in?
    false
  end
end