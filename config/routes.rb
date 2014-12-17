Mercator::Application.routes.draw do
  get 'admin/test_payment' => 'orders#test_payment', :as => 'test_payment'
end
