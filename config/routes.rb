Mercator::Application.routes.draw do
  get 'admin/test_payment' => 'orders#test_payment', :as => 'test_payment'
end

MercatorMpay24::Engine.routes.draw do
  get 'confirmation' => 'confirmations#create', :as => 'create_confirmation'
end