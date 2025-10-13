# frozen_string_literal: true

module SessionHelper
  def with_cart_session(cart)
    { 'rack.session' => { cart_id: cart.id } }
  end
end

RSpec.configure do |config|
  config.include SessionHelper, type: :request
end
