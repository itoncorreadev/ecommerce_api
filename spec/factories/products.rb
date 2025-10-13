# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    price { Faker::Commerce.price(range: 1.0..200.0) }

    trait :expensive do
      price { Faker::Commerce.price(range: 500.0..5000.0) }
    end

    trait :cheap do
      price { Faker::Commerce.price(range: 1.0..10.0) }
    end
  end
end
