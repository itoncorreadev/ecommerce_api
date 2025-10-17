# frozen_string_literal: true

class Cart < ApplicationRecord
  include CartTiming

  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :set_default_total_price
  before_save :calculate_total_price
  before_create :set_last_interaction_at

  scope :abandoned, -> { where.not(abandoned_at: nil) }
  scope :not_abandoned, -> { where(abandoned_at: nil) }

  def abandoned?
    abandoned_at.present?
  end

  def mark_as_abandoned
    update(abandoned_at: Time.current) if should_be_abandoned?
  end

  def remove_if_abandoned
    destroy if abandoned? && abandoned_for_too_long?
  end

  def update_interaction
    CartService.update_interaction(self)
  end

  def add_product(product, quantity = 1)
    CartService.add_product(self, product, quantity)
  end

  def remove_product(product)
    CartService.remove_product(self, product)
  end

  def update_product_quantity(product, quantity)
    CartService.update_product_quantity(self, product, quantity)
  end

  private

  def calculate_total_price
    CartService.calculate_total_price(self)
  end

  def set_last_interaction_at
    self.last_interaction_at ||= Time.current
  end

  def set_default_total_price
    self.total_price ||= 0.0
  end
end
