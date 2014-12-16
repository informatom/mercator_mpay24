module Mpay24OrderExtensions

  # --- Instance Methods --- #
  def to_mpay24_xml
    xml = Builder::XmlMarkup.new(:indent => 2)

    xml.Order do
      xml.Tid self.erp_order_number
      xml.Price "%0.2f" % self.sum_incl_vat
    end
  end

  def payment
    begin
      merchant_id = Constant.find_by_key("mpay24_merchant_id").try(:value) || CONFIG[:mpay24_merchant_id]

      mpay24_response = MercatorMpay24::Gateway.new(merchant_id: merchant_id,
                                                    tid: erp_order_number,
                                                    order_xml: to_mpay24_xml)
                                               .get_response
      @wmbi_url = mpay24_response['LOCATION'].try(:first)
      render :action => :payment
    rescue Exception => e
      puts "MPAY24 EXCEPTION : #{e}"
      logger.error "MPAY24 EXCEPTION : #{e}"
      return false
    end
  end
end