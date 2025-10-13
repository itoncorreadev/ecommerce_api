# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Products', type: :request do
  path '/products' do
    get 'Lista produtos' do
      tags 'Product list'
      produces 'application/json'

      response '200', 'listed products' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Product' }

        before do
          create_list(:product, 2)
        end

        run_test!
      end
    end
  end

  path '/products/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true

    get 'Show product' do
      tags 'Products'
      produces 'application/json'

      response '200', 'product found' do
        let(:product) { create(:product) }
        let(:id) { product.id }

        run_test!
      end

      response '404', 'product not found' do
        let(:id) { 9999 }
        run_test!
      end
    end

    put 'Update product' do
      tags 'Products'
      consumes 'application/json'
      parameter name: :product, in: :body, schema: { '$ref' => '#/components/schemas/Product' }

      response '200', 'updated product' do
        let(:product_a) { create(:product) }
        let(:id) { product_a.id }
        let(:product) { { name: 'Novo nome', price: 10.0 } }

        run_test!
      end

      response '404', 'product not found' do
        let(:id) { 9999 }
        let(:product) { { name: 'Teste', price: 1.0 } }

        run_test!
      end
    end

    delete 'Remove product' do
      tags 'Products'

      response '204', 'product deleted' do
        let(:product) { create(:product) }
        let(:id) { product.id }

        run_test!
      end

      response '404', 'product not found' do
        let(:id) { 9999 }
        run_test!
      end
    end
  end
end
