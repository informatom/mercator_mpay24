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
  end
end