module MercatorMpay24
  class Confirmation < ActiveRecord::Base
    hobo_model

    fields do
      operation      :string
      tid            :string
      status         :string
      price          :string
      currency       :string
      p_type         :string
      brand          :string
      mpaytid        :string
      user_field     :string
      orderdesc      :string
      customer       :string
      customer_email :string
      language       :string
      customer_id    :string
      profile_status :string
      filter_status  :string
      appr_code      :string
      timestamps
    end

    attr_accessible :operation, :tid, :status, :price, :currency, :p_type, :brand, :mpaytid,
                    :user_field, :orderdesc, :customer, :customer_email, :language, :customer_id,
                    :profile_status, :filter_status, :appr_code
    has_paper_trail

    belongs_to :payment

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