# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Carts', type: :request do
  path '/cart' do
    get 'List cart items' do
      tags 'Cart'
      produces 'application/json'

      response 200, 'returned cart' do
        schema '$ref' => '#/components/schemas/Cart'
        run_test!
      end
    end

    post 'Create a new cart' do
      tags 'Cart'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    product_id: { type: :integer },
                    quantity: { type: :integer, minimum: 1 }
                  },
                  required: ['product_id']
                }

      response 201, 'cart created' do
        let!(:product) { create(:product) }
        let(:payload) { { product_id: product.id, quantity: 1 } }
        schema '$ref' => '#/components/schemas/Cart'
        run_test!
      end

      response 404, 'product not found' do
        let(:payload) { { product_id: -1, quantity: 1 } }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response 422, 'invalid quantity' do
        let!(:product) { create(:product) }
        let(:payload) { { product_id: product.id, quantity: 0 } }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end

  path '/cart/add_item' do
    post 'Add item to cart (or change quantity)' do
      tags 'Cart'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    product_id: { type: :integer },
                    quantity: { type: :integer, minimum: 1 }
                  },
                  required: ['product_id']
                }

      response 200, 'item added' do
        let!(:product) { create(:product) }
        let(:payload) { { product_id: product.id, quantity: 2 } }
        schema '$ref' => '#/components/schemas/Cart'
        run_test!
      end

      response 422, 'invalid quantity' do
        let!(:product) { create(:product) }
        let(:payload) { { product_id: product.id, quantity: 0 } }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response 404, 'product not found' do
        let(:payload) { { product_id: -1, quantity: 1 } }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end

  path '/cart/{product_id}' do
    delete 'Remove item from cart' do
      tags 'Cart'
      produces 'application/json'

      parameter name: :product_id, in: :path, type: :integer, description: 'Product ID'

      response 200, 'item removed' do
        let!(:product) { create(:product) }
        let!(:cart) { create(:cart) }
        let(:product_id) { product.id }

        before do
          cart.add_product(product, 1)
        end

        schema '$ref' => '#/components/schemas/Cart'
        run_test!
      end

      response 404, 'product not found' do
        let(:product_id) { -1 }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response 422, 'invalid removal' do
        let!(:product) { create(:product) }
        let(:product_id) { product.id }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end
end
