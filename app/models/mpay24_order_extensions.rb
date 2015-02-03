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

    payment = MercatorMpay24::Payment.create(merchant_id: merchant_id,
                                             order_id: id)
    payment.update(order_xml: XmlMessage.new(order: self,
                                             merchant_id: merchant_id,
                                             tid: payment.id).to_s,
                   tid: payment.id)

    puts Order::MPAY_TEST_CLIENT.operation(:select_payment)
                                .build(message: XmlMessage.new(order: self,
                                       merchant_id: merchant_id,
                                       tid: payment.id))
                                .to_s

    response = client.call(:select_payment,
                           message: XmlMessage.new(order: self,
                                                   merchant_id: merchant_id,
                                                   tid: payment.id))
    return response
  end

  class XmlMessage
    attr_accessor(:order, :merchant_id, :tid)

    def initialize(params)
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def to_s()
      xml = Builder::XmlMarkup.new()
      xml.merchantID merchant_id
      xml.mdxi do
        xml.Order do
          xml.Tid tid
          xml.ShoppingCart do
            xml.Description order.name
            order.lineitems.each do |lineitem|
              xml.Item do
                xml.Number lineitem.position
                xml.ProductNr lineitem.product_number
                xml.Description lineitem.description.tr("\n\r\t","   ")
                xml.Quantity lineitem.amount.to_i
                xml.ItemPrice sprintf( "%0.02f", lineitem.product_price)
                xml.Price sprintf( "%0.02f", lineitem.value)
              end
            end
            xml.ShippingCosts(sprintf( "%0.02f", order.shipping_cost),
                              "Tax" => sprintf( "%0.02f", order.shipping_cost_vat) )
            xml.Tax sprintf( "%0.02f", order.vat)
            xml.Discount sprintf( "%0.02f", order.discount)
          end
          xml.Price sprintf( "%0.02f", order.sum_incl_vat)
          xml.URL do
            xml.Success "http://localhost:3000/order/success"
            xml.Error "http://localhost:3000/order/error"
            xml.Confirmation "http://www.informatom.com/mercator_mpay24/confirmation"
            xml.Cancel "http://localhost:3000/order/cancel"
          end
        end
      end
    end
  end
end