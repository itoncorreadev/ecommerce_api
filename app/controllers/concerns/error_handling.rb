# frozen_string_literal: true

module ErrorHandling
  extend ActiveSupport::Concern

  private

  def render_validation_errors(object, status: :unprocessable_entity)
    render json: { errors: object.errors.full_messages }, status: status
  end

  def render_not_found_error(message = 'Resource not found')
    render json: { error: message }, status: :not_found
  end

  def render_quantity_error(cart = nil)
    cart ||= CartService.find_or_create_cart(
      session_cart_id: session[:cart_id],
      product_id: params[:product_id]
    )
    cart.errors.add(:quantity, 'must be greater than 0')
    render_validation_errors(cart)
  end

  def validate_positive_quantity
    quantity = params[:quantity].to_i
    return quantity if quantity.positive?

    render_quantity_error
    nil
  end
end
