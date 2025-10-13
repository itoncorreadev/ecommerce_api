# frozen_string_literal: true

class CartSerializer < ActiveModel::Serializer
  attributes :id, :products

  def products
    object.cart_items.includes(:product).map do |item|
      CartItemSerializer.new(item).as_json
    end
  end

  attributes :total_price

  def total_price
    object.total_price.to_f
  end
end
