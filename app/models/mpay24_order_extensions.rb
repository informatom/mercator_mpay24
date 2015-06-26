module Mpay24OrderExtensions

  extend ActiveSupport::Concern

  included do
    has_many :payments, :class_name => "MercatorMpay24::Payment"
  end

  if Constant.table_exists?
    MERCHANT_TEST_ID = Constant.find_by_key("mpay_test_username").try(:value) || "undefined"
    MPAY_TEST_CLIENT =
      Savon.client(basic_auth: ["u" + MERCHANT_TEST_ID,
                                      Constant.find_by_key("mpay_test_password").try(:value) ],
                   wsdl: "https://test.mpay24.com/soap/etp/1.5/ETP.wsdl",
                   endpoint: "https://test.mpay24.com/app/bin/etpproxy_v15",
                   logger: Rails.logger, log_level: :info, log: true, pretty_print_xml: true)

    MERCHANT_PRODUCTION_ID = Constant.find_by_key("mpay_production_username").try(:value) || "undefined"
    MPAY_PRODUCTION_CLIENT =
      Savon.client(basic_auth: ["u" + MERCHANT_PRODUCTION_ID,
                                      Constant.find_by_key("mpay_test_password").try(:value) ],
                   wsdl: "https://www.mpay24.com/soap/etp/1.5/ETP.wsdl",
                   endpoint: "https://www.mpay24.com/app/bin/etpproxy_v15",
                   logger: Rails.logger, log_level: :info, log: true, pretty_print_xml: true)
  end

  # --- Instance Methods --- #
  def pay(system: nil)
    case system
      when "production"
        @client = MPAY_PRODUCTION_CLIENT
        @merchant_id = MERCHANT_PRODUCTION_ID
      else
        @client = MPAY_TEST_CLIENT
        @merchant_id = MERCHANT_TEST_ID
    end

    @payment = MercatorMpay24::Payment.create(merchant_id: @merchant_id, order_id: id )
    user_field_hash = Digest::SHA256.hexdigest (@payment.id.to_s + self.sum_incl_vat.to_s + "EUR" +
                                     Time.now.to_s + SecureRandom.hex)
    @payment.update(user_field_hash: user_field_hash, tid: @payment.id)
    @xml_message = XmlMessage.new(order: self, payment: @payment)
    @payment.update(order_xml: @xml_message.to_s )

#   Console Output for Debugging:
#   puts Order::MPAY_TEST_CLIENT.operation(:select_payment)
#                               .build(message: XmlMessage.new(order: self, payment: @payment))
#                               .to_s

    logger.info Order::MPAY_TEST_CLIENT.operation(:select_payment)
                                       .build(message: XmlMessage.new(order: self, payment: @payment))
                                       .to_s

    @response = @client.call(:select_payment, message: @xml_message)
    return @response
  end

  class XmlMessage
    attr_accessor(:order, :payment)

    def initialize(params)
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def to_s()
      xml = Builder::XmlMarkup.new()
      xml.merchantID payment.merchant_id
      xml.mdxi do
        xml.Order do
          xml.UserField payment.user_field_hash
          xml.Tid payment.id
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
            xml.Success Rails.application.routes.url_helpers.payment_status_order_url(order.id, domain: ::Constant::SHOPDOMAIN)
            xml.Error Rails.application.routes.url_helpers.payment_status_order_url(order.id, domain: ::Constant::SHOPDOMAIN)
            xml.Confirmation Rails.application.routes.url_helpers.create_confirmation_url(domain: ::Constant::SHOPDOMAIN)
            xml.Cancel Rails.application.routes.url_helpers.payment_status_order_url(order.id, domain: ::Constant::SHOPDOMAIN)
          end
        end
      end
    end
  end
end