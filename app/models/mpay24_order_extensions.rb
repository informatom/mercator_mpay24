module Mpay24OrderExtensions

  extend ActiveSupport::Concern

  included do
    has_many :payments
  end

  MERCHANT_TEST_ID = Constant.find_by_key("mpay_test_username").value
  MPAY_TEST_CLIENT =
    Savon.client(basic_auth: ["u" + MERCHANT_TEST_ID,
                                    Constant.find_by_key("mpay_test_password").value ],
                 wsdl: "https://test.mpay24.com/soap/etp/1.5/ETP.wsdl",
                 endpoint: "https://test.mpay24.com/app/bin/etpproxy_v15",
                 logger: Rails.logger, log_level: :info, log: true, pretty_print_xml: true)


  MERCHANT_PRODUCTION_ID = try_to("") {Constant.find_by_key("mpay_production_username").value}
  MPAY_PRODUCTION_CLIENT =
    Savon.client(basic_auth: ["u" + MERCHANT_PRODUCTION_ID,
                                    try_to("") {Constant.find_by_key("mpay_test_password").value} ],
                 wsdl: "FIXME!",
                 endpoint: "FIXME!",
                 logger: Rails.logger, log_level: :info, log: true, pretty_print_xml: true)


  # --- Instance Methods --- #
  def pay(system: nil)
    case system
      when "production"
        client = MPAY_PRODUCTION_CLIENT
        merchant_id = MERCHANT_PRODUCTION_ID
      else
        client = MPAY_TEST_CLIENT
        merchant_id = MERCHANT_TEST_ID
    end

    MercatorMpay24::Payment.create(merchant_id: merchant_id, tid: erp_order_number,
                                   order_xml: XmlMessage.new(order: self, merchant_id: merchant_id), order_id: id)

    client.call(:select_payment, message: XmlMessage.new(order: self, merchant_id: merchant_id))
  end

  class XmlMessage
    attr_accessor(:order, :merchant_id)

    def initialize(params)
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def to_s()
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct! :xml, :encoding => "UTF-8"
      xml.merchant_id merchant_id
      xml.mdxi do
        xml.Order do
          xml.Tid order.erp_order_number
          xml.Price order.sum_incl_vat
          xml.ShoppingCart do
            xml.Description order.name
            xml.ShippingCosts(order.shipping_cost, "Tax" => order.shipping_cost_vat)
            xml.Tax order.vat
            xml.Discount order.discount
            order.lineitems.each do |lineitem|
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
  end
end