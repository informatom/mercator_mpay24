# encoding: utf-8

namespace :orders do

  # starten als: rake orders:test_payment
  # in Produktivumgebungen: bundle exec rake orders:test_payment RAILS_ENV=production
  desc "Test payment interface"
  task :test_payment => :environment do
    @testorder = Order.new(erp_order_number: 98765432123456789)
    @testorder.payment
  end
end
