# frozen_string_literal: true

class CartItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :unit_price, :quantity, :total_price

  def id
    object.product.id
  end

  def name
    object.product.name
  end

  def unit_price
    object.product.price.to_f
  end

  def total_price
    object.total_price.to_f
  end
end
