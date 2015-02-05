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
      profile_id     :string
      profile_status :string
      filter_status  :string
      appr_code      :string
      timestamps
    end

    attr_accessible :operation, :tid, :status, :price, :currency, :p_type, :brand, :mpaytid,
                    :user_field, :orderdesc, :customer, :customer_email, :language, :customer_id,
                    :profile_id, :profile_status, :filter_status, :appr_code, :payment_id, :payment
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

    def update_order
      @order = self.payment.order

      case self.status
        when *["ERROR", "REVERSED", "CREDITED"]
          @order.lifecycle.failing_payment!(User.find_by(surname: "MPay24"))
        when *["RESERVED", "SUSPENDED"]
          nil
        when "BILLED"
          # Security Check in case of AP spoofing
          if self.payment.user_field_hash == self.user_field
            @order.lifecycle.successful_payment!(User.find_by(surname: "MPay24"))
            if Rails.application.config.try(:erp) == "mesonic" && Rails.env == "production"
              # A quick ckeck, if erp_account_number is current
              # (User could have been changed since last job run)
              @order.user.update_erp_account_nr()

              @order.push_to_mesonic()
            end
          else
            @order.lifecycle.failing_payment!(User.find_by(surname: "MPay24"))
          end
      end
    end
  end
end