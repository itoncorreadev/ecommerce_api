# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart).not_to be_valid
      expect(cart.errors[:total_price]).to include('must be greater than or equal to 0')
    end

    it 'defaults total_price to 0.0 after initialize' do
      cart = described_class.new
      expect(cart.total_price).to eq(0.0)
    end

    it 'sets last_interaction_at on create' do
      cart = create(:shopping_cart)
      expect(cart.last_interaction_at).to be_present
    end
  end

  describe 'mark_as_abandoned' do
    let(:shopping_cart) { create(:shopping_cart) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      shopping_cart.update(last_interaction_at: 3.hours.ago)
      expect { shopping_cart.mark_as_abandoned }.to change(shopping_cart, :abandoned?).from(false).to(true)
    end

    it 'does not mark as abandoned if interaction is recent' do
      shopping_cart.update(last_interaction_at: 1.hour.ago)
      expect { shopping_cart.mark_as_abandoned }.not_to(change(shopping_cart, :abandoned?))
    end
  end

  describe 'remove_if_abandoned' do
    let(:shopping_cart) { create(:shopping_cart, last_interaction_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      shopping_cart.mark_as_abandoned
      expect { shopping_cart.remove_if_abandoned }.to change(Cart, :count).by(-1)
    end

    it 'does not remove if not abandoned' do
      cart = create(:shopping_cart, last_interaction_at: 7.days.ago)
      expect { cart.remove_if_abandoned }.not_to(change(Cart, :count))
    end

    it 'does not remove if abandoned but not long enough' do
      cart = create(:shopping_cart, last_interaction_at: 6.days.ago)
      cart.mark_as_abandoned
      expect { cart.remove_if_abandoned }.not_to(change(Cart, :count))
    end
  end

  describe 'scopes' do
    it 'abandoned returns carts with abandoned_at present' do
      create(:cart, abandoned_at: 2.hours.ago)
      create(:cart)
      expect(Cart.abandoned.count).to be >= 1
      expect(Cart.abandoned.all?(&:abandoned?)).to be(true)
    end

    it 'not_abandoned returns carts without abandoned_at' do
      create(:cart)
      create(:cart, abandoned_at: 2.hours.ago)
      expect(Cart.not_abandoned.count).to be >= 1
      expect(Cart.not_abandoned.none?(&:abandoned?)).to be(true)
    end

    it 'inactive_for includes carts with last_interaction before threshold' do
      active = create(:cart)
      inactive = create(:cart, last_interaction_at: 3.hours.ago)
      result = Cart.inactive_for(2.hours.ago)
      expect(result).to include(inactive)
      expect(result).not_to include(active)
    end

    it 'inactive_for falls back to integer seconds (else branch)' do
      active = create(:cart)
      inactive = create(:cart)
      active.update!(last_interaction_at: 1.hour.ago)
      inactive.update!(last_interaction_at: 3.hours.ago)

      # Pass numeric seconds to hit the else branch (value.to_i)
      result = Cart.inactive_for(7200)
      expect(result).to include(inactive)
      expect(result).not_to include(active)
    end
  end

  describe 'total_price calculation (callback)' do
    it 'recalculates total_price before save' do
      cart = create(:shopping_cart, total_price: 0.0)
      product_a = create(:product, price: 10.0)
      product_b = create(:product, price: 5.0)
      create(:cart_item, cart: cart, product: product_a, quantity: 2)
      create(:cart_item, cart: cart, product: product_b, quantity: 3)

      cart.save
      expect(cart.total_price).to eq(35.0)
    end
  end

  describe 'service delegation' do
    it 'delegates update_interaction to CartService' do
      cart = create(:shopping_cart)
      expect(CartService).to receive(:update_interaction).with(cart)
      cart.update_interaction
    end

    it 'delegates update_product_quantity to CartService with args' do
      cart = create(:shopping_cart)
      product = create(:product, :expensive)
      expect(CartService).to receive(:update_product_quantity).with(cart, product, 3)
      cart.update_product_quantity(product, 3)
    end
  end
end
