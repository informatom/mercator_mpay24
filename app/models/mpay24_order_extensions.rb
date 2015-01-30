module Mpay24OrderExtensions

  # --- Instance Methods --- #
  def payment
    client = Order.test_cliest

    Payment.create(merchant_id: merchant_id,
                   tid: erp_order_numbe,
                   order_xml: to_mpay24_xml,
                   order_id: id)

    client.call(:select_payment, xml: xml_message)
  end

  def xml_message
    xml = Builder::XmlMarkup.new( :indent => 2 )
    xml.instruct! :xml, :encoding => "UTF8"
    xml.merchant_id Constant.find_by_key("mpay_test_username").value
    xml.mdxi do
      xml.order do
        xml.Tid erp_order_number
        xml.Price sum_incl_vat
        xml.ShoppingCart do
          xml.Description self.name
          xml.ShippingCosts(shipping_cost, "Tax" => shipping_cost_vat)
          xml.Tax vat
          xml.Discount discount
          lineitems.each do |lineitem|
            xml.Item do
              xml.Number lineitem.position
              xml.ProductNr lineitem.product_number
              xml.Description lineitem.description
              xml.Quantity lineitem.amount
              xml.ItemPrice lineitem.product_price
              xml.Price lineitem.value
            end
          end
        end
      end
    end
  end

  # --- Calass Methods --- #
  def self.test_client
    Savon.client(basic_auth: ["u" + Constant.find_by_key("mpay_test_username").value,
                                    Constant.find_by_key("mpay_test_password").value ],
                 wsdl:       "https://test.mpay24.com/soap/etp/1.5/ETP.wsdl",
                 endpoint:   "https://test.mpay24.com/app/bin/etpproxy_v15",
                 logger:     Rails.logger,
                 log_level:  :info,
                 log:        true,
                 pretty_print_xml: true)
  end
end