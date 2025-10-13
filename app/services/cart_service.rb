# frozen_string_literal: true

class CartService
  class << self
    def find_or_create_cart(session_cart_id: nil, product_id: nil)
      find_cart_by_session(session_cart_id) ||
        find_recent_cart_for_product(product_id) ||
        find_recent_cart_with_items ||
        find_last_created_cart ||
        Cart.create!
    end

    def add_product(cart, product, quantity = 1)
      cart_item = cart.cart_items.find_by(product: product)
      success = false

      if cart_item
        success = cart_item.update(quantity: cart_item.quantity + quantity)
      else
        new_item = cart.cart_items.create(product: product, quantity: quantity)
        success = new_item.persisted?
      end
      finalize(cart, success ? cart : false)
    end

    def remove_product(cart, product)
      cart_item = cart.cart_items.find_by(product: product)
      return false unless cart_item

      cart_item.destroy
      finalize(cart, true)
    end

    def update_product_quantity(cart, product, quantity)
      cart_item = cart.cart_items.find_by(product: product)
      return false unless cart_item

      if quantity <= 0
        cart_item.destroy
      else
        cart_item.update(quantity: quantity)
      end
      finalize(cart, true)
    end

    def update_interaction(cart)
      cart.update(last_interaction_at: Time.current)
    end

    def calculate_total_price(cart)
      items = cart.cart_items.includes(:product).to_a
      cart.total_price = items.sum { |item| item.quantity * item.product.price }
    end

    private

    def find_cart_by_session(session_cart_id)
      return unless session_cart_id

      Cart.find_by(id: session_cart_id)
    end

    def find_recent_cart_for_product(product_id)
      return unless product_id

      CartItem.where(product_id: product_id)
              .order(created_at: :desc)
              .limit(1)
              .first&.cart
    end

    def find_recent_cart_with_items
      Cart.joins(:cart_items).order('carts.created_at DESC').first
    end

    def find_last_created_cart
      Cart.order(created_at: :desc).first
    end

    def finalize(cart, return_value = true)
      update_interaction(cart)
      cart.reload
      return_value
    end
  end
end
