# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CartService, type: :service do
  let(:cart) { create(:shopping_cart, total_price: 0.0) }
  let(:product_a) { create(:product, price: 10.0, name: 'Product A') }
  let(:product_b) { create(:product, price: 5.0, name: 'Product B') }

  describe '.add_product' do
    it 'creates a new item when product does not exist' do
      expect do
        CartService.add_product(cart, product_a, 2)
      end.to change { cart.cart_items.count }.by(1)

      cart.reload
      item = cart.cart_items.find_by(product: product_a)
      expect(item.quantity).to eq(2)
      expect(cart.total_price).to eq(20.0)
    end

    it 'increments the quantity when product already exists' do
      create(:cart_item, cart: cart, product: product_a, quantity: 1)

      expect do
        CartService.add_product(cart, product_a, 3)
      end.to change { cart.cart_items.find_by(product: product_a).quantity }.from(1).to(4)

      cart.reload
      expect(cart.total_price).to eq(40.0)
    end

    it 'returns the cart itself' do
      result = CartService.add_product(cart, product_b, 1)
      expect(result).to eq(cart)
    end
  end

  describe '.remove_product' do
    it 'removes the item and returns true' do
      create(:cart_item, cart: cart, product: product_a, quantity: 2)
      CartService.calculate_total_price(cart)
      expect(cart.total_price).to eq(20.0)

      expect(CartService.remove_product(cart, product_a)).to be(true)
      cart.reload
      expect(cart.cart_items.find_by(product: product_a)).to be_nil
      expect(cart.total_price).to eq(0.0)
    end

    it 'returns false if item does not exist' do
      expect(CartService.remove_product(cart, product_a)).to be(false)
    end
  end

  describe '.update_product_quantity' do
    it 'updates the quantity when > 0' do
      create(:cart_item, cart: cart, product: product_a, quantity: 2)

      expect(CartService.update_product_quantity(cart, product_a, 5)).to be(true)
      cart.reload
      item = cart.cart_items.find_by(product: product_a)
      expect(item.quantity).to eq(5)
      expect(cart.total_price).to eq(50.0)
    end

    it 'removes the item when quantity <= 0' do
      create(:cart_item, cart: cart, product: product_a, quantity: 1)

      expect(CartService.update_product_quantity(cart, product_a, 0)).to be(true)
      cart.reload
      expect(cart.cart_items.find_by(product: product_a)).to be_nil
      expect(cart.total_price).to eq(0.0)
    end
  end

  describe '.calculate_total_price' do
    it 'calculates the total by summing quantity x price of each item' do
      create(:cart_item, cart: cart, product: product_a, quantity: 2) # 20
      create(:cart_item, cart: cart, product: product_b, quantity: 3) # 15

      CartService.calculate_total_price(cart)
      expect(cart.total_price).to eq(35.0)
    end
  end
end
