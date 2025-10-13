# frozen_string_literal: true

FactoryBot.define do
  factory :cart_item do
    association :cart
    association :product
    quantity { Faker::Number.between(from: 1, to: 5) }
  end
end
