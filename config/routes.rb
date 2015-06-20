Mercator::Application.routes.draw do
  get 'admin/test_payment' => 'orders#test_payment', :as => 'test_payment'

  namespace "admin" do
    get 'payments/:id/check_confirmation' => 'payments#check_confirmation', :as => 'check_confirmation'
  end
end

MercatorMpay24::Engine.routes.draw do
  get 'confirmation' => 'confirmations#create', :as => 'create_confirmation'
end