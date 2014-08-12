module Mpay24OrderExtensions

  # --- Instance Methods --- #
  def to_mpay24_xml
    price = "%0.2f" % self.sum_incl_vat

    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.Order do
      xml.Tid self.erp_order_number
      xml.Price self.price
    end
  end
end