module MercatorMpay24
  class Engine < ::Rails::Engine

    isolate_namespace MercatorMpay24
    config.payment = "mpay24"
  end
end
