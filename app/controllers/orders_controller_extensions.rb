module OrdersControllerExtensions
  extend ActiveSupport::Concern

  included do
    def test_payment
      # Request.body to console
      puts ap(Order::MPAY_TEST_CLIENT.operation(:select_payment)
                                  .build(message: XmlTestMessage.new)
                                  .to_s)

      response = Order::MPAY_TEST_CLIENT.call(:select_payment, message: XmlTestMessage.new)

      if response.body[:select_payment_response][:location]
        redirect_to response.body[:select_payment_response][:location]
      else
        render :show
        puts "Error:" + response.body[:select_payment_response][:err_text]
      end
    end
  end

  class XmlTestMessage
    def to_s()
      xml = Builder::XmlMarkup.new()
      xml.merchantID Order::MERCHANT_TEST_ID
      xml.mdxi do
        xml.Order do
          xml.Tid "0815/4711"
          xml.Price "12.34"
        end
      end
    end
  end
end