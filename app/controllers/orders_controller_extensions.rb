module OrdersControllerExtensions
  extend ActiveSupport::Concern

  included do
    def test_payment
      client = Order.test_cliest
      response = client.call(:select_payment, xml: xml_test_message)

      if response.body[:select_payment_response]
        redirect_to response.body[:select_payment_response][:location]
      else
        puts "Error: Response is not of the expected format."
      end
    end
  end

  private
  def xml_test_message
    xml = Builder::XmlMarkup.new( :indent => 2 )
    xml.instruct! :xml, :encoding => "UTF-8"
    xml.merchant_id Order::MERCHANT_TEST_ID
    xml.mdxi do
      xml.Order do
        xml.Tid "0815/4711"
        xml.Price "12.34"
      end
    end
  end
end