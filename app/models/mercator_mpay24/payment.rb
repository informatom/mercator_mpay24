module MercatorMpay24
  class Payment < ActiveRecord::Base
    hobo_model

    fields do
      merchant_id     :string
      tid             :string
      user_field_hash :string
      order_xml       :text
      timestamps
    end

    attr_accessible :merchant_id, :tid, :order_xml, :order, :order_id, :user_field_hash
    has_paper_trail

    belongs_to :order
    has_many :confirmations

    # --- Permissions --- #
    def create_permitted?
      true
    end

    def update_permitted?
      false
    end

    def destroy_permitted?
      false
    end

    def view_permitted?(field)
      acting_user.administrator? ||
      acting_user.sales?
    end

    #--- Instance Methods ---#
    def check_transaction_status
      case Rails.env
        when "production"
          client = Order::MPAY_PRODUCTION_CLIENT
          merchant_id = Order::MERCHANT_PRODUCTION_ID
        else
          client = Order::MPAY_TEST_CLIENT
          merchant_id = Order::MERCHANT_TEST_ID
      end

      response = client.call(:transaction_status, message: {merchantID: merchant_id ,
                                                            tid: self.tid })

      @confirmation = Confirmation.new()
      if response.body[:transaction_status_response][:status] == "ERROR"
        @confirmation.assign_attributes(status: response.body[:transaction_status_response][:return_code],
                                        payment_id: self.id)
        @confirmation.save
      else
        response.body[:transaction_status_response][:parameter].each do |hash|
          @confirmation.assign_attributes(hash[:name].downcase => hash[:value])
          @confirmation.payment_id = self.id
        end
        @confirmation.save
        @confirmation.update_order
      end
    end
  end
end