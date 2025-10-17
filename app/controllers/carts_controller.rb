# frozen_string_literal: true

class CartsController < ApplicationController
  before_action :set_cart, only: %i[show create add_item remove_item]
  before_action :set_product, only: %i[create add_item remove_item]

  # GET /cart
  def show
    @cart.update_interaction
    render json: @cart, serializer: CartSerializer, status: :ok
  end

  # POST /cart
  def create
    if @product.present?
      quantity = validate_positive_quantity
      return unless quantity

      @cart.add_product(@product, quantity)
    end

    render json: @cart, serializer: CartSerializer, status: :created
  end

  # POST /cart/add_item
  def add_item
    quantity = validate_positive_quantity
    return unless quantity

    add_item_and_render(quantity)
  end

  # DELETE /cart/:product_id
  def remove_item
    if @cart.remove_product(@product)
      render json: @cart, serializer: CartSerializer, status: :ok
    else
      render_validation_errors(@cart)
    end
  end

  private

  def set_cart
    cart_id = params[:id] || params[:cart_id] || session[:cart_id]
    @cart = CartService.find_or_create_cart(session_cart_id: cart_id, product_id: params[:product_id])
    session[:cart_id] ||= @cart.id
  end

  def set_product
    return if params[:product_id].blank?

    @product = Product.find_by(id: params[:product_id])
    return if @product.present?

    render_not_found_error('Product not found')
  end

  def cart_summary; end

  def add_item_and_render(quantity)
    if @cart.add_product(@product, quantity)
      render json: @cart, serializer: CartSerializer, status: :ok
    else
      render_validation_errors(@cart)
    end
  end
end
