# frozen_string_literal: true

FactoryBot.define do
  factory :cart do
    total_price { Faker::Commerce.price(range: 0.0..500.0) }
    last_interaction_at { Faker::Time.between(from: 1.hour.ago, to: Time.current) }

    trait :abandoned do
      abandoned_at { Faker::Time.between(from: 2.hours.ago, to: 1.hour.ago) }
      last_interaction_at { 3.hours.ago }
    end

    trait :inactive do
      last_interaction_at { Faker::Time.between(from: 6.hours.ago, to: 3.hours.ago) }
    end
  end

  factory :shopping_cart, class: 'Cart' do
    total_price { Faker::Commerce.price(range: 0.0..500.0) }
    last_interaction_at { Faker::Time.between(from: 1.hour.ago, to: Time.current) }
  end
end
