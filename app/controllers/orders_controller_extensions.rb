module OrdersControllerExtensions
  extend ActiveSupport::Concern

  included do
    def test_payment
      client = Order.test_cliest
      response = client.call(:select_payment,
                              message: {merchantID: Constant.find_by_key("mpay_test_username").value,
                                        mdxi: {"Order" => {"Tid" => "0815/4711",
                                                           "Price" => "12.34"}}})

      if response.body[:select_payment_response]
        redirect_to response.body[:select_payment_response][:location]
      else
        puts "Error: Response is not of the expected format."
      end
    end
  end
end