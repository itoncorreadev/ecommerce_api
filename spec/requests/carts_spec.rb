# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/cart', type: :request do
  describe 'POST /cart/add_item' do
    let(:cart) { create(:shopping_cart) }
    let(:product) { create(:product, price: 10.0) }
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      subject do
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end
    end
  end

  describe 'POST /cart' do
    it 'adds a product to the cart and returns 201 with full JSON' do
      product = create(:product, price: 10.0)
      post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json['id']).to be_present
      expect(json['total_price'].to_f).to eq(20.0)
      expect(json['products']).to be_an(Array)
      expect(json['products'].size).to eq(1)
      item = json['products'].first
      expect(item['id']).to eq(product.id)
      expect(item['name']).to eq(product.name)
      expect(item['unit_price'].to_f).to eq(10.0)
      expect(item['quantity']).to eq(2)
      expect(item['total_price'].to_f).to eq(20.0)
    end
  end

  describe 'POST /cart with invalid product' do
    it 'returns 404 when product_id does not exist' do
      post '/cart', params: { product_id: 999_999, quantity: 1 }, as: :json
      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json['error']).to eq('Product not found')
    end
  end

  describe 'GET /cart' do
    let!(:cart) { create(:shopping_cart) }
    let!(:product) { create(:product, :cheap) }
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

    it 'returns the cart in JSON with a products list' do
      get '/cart', as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['id']).to eq(cart.id)
      expect(json['products']).to be_an(Array)
      expect(json['products'].first['id']).to eq(product.id)
    end
  end

  describe 'GET /cart session persistence' do
    it 'keeps returning the initial session cart across requests' do
      get '/cart', as: :json
      expect(response).to have_http_status(:ok)
      first_id = response.parsed_body['id']

      create(:shopping_cart)

      get '/cart', as: :json
      expect(response).to have_http_status(:ok)
      second_id = response.parsed_body['id']
      expect(second_id).to eq(first_id)
    end
  end

  describe 'POST /cart without product_id' do
    it 'returns 201 and does not modify products' do
      post '/cart', as: :json
      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json['products']).to be_an(Array)
      expect(json['products']).to be_empty
      expect(json['total_price'].to_f).to eq(0.0)
    end
  end

  describe 'POST /cart/add_item' do
    let!(:cart) { create(:shopping_cart, total_price: 0.0) }
    let!(:product) { create(:product, price: 10.0) }

    it 'increments the item quantity and returns the full cart' do
      create(:cart_item, cart: cart, product: product, quantity: 1)
      post '/cart/add_item', params: { product_id: product.id, quantity: 3 }, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['total_price'].to_f).to eq(40.0)
      item = json['products'].find { |i| i['id'] == product.id }
      expect(item['quantity']).to eq(4)
      expect(item['unit_price'].to_f).to eq(10.0)
      expect(item['total_price'].to_f).to eq(40.0)
    end

    it 'returns 422 and error payload when quantity is invalid (zero)' do
      post '/cart/add_item', params: { product_id: product.id, quantity: 0 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['errors']).to be_an(Array)
      expect(json['errors']).not_to be_empty
      cart.reload
      expect(cart.cart_items.find_by(product: product)).to be_nil
    end

    it 'returns 422 when adding the product fails in the service' do
      allow(CartService).to receive(:add_product).and_return(false)
      post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['errors']).to be_an(Array)
    end
  end

  describe 'DELETE /cart/:product_id' do
    let!(:cart) { create(:shopping_cart, total_price: 0.0) }
    let!(:product) { create(:product, price: 10.0) }

    it 'removes an existing item and returns the full cart' do
      create(:cart_item, cart: cart, product: product, quantity: 2)
      delete "/cart/#{product.id}", as: :json
      expect(response).to have_http_status(:ok)
      response.parsed_body
      cart.reload
      expect(cart.cart_items.find_by(product: product)).to be_nil
      expect(cart.total_price).to eq(0.0)
    end

    it 'returns 422 when item does not exist in cart' do
      delete "/cart/#{product.id}", as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['errors']).to be_an(Array)
    end
  end

  describe 'GET /cart with id param' do
    it 'creates a new cart when no session exists' do
      get '/cart', as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['id']).to be_present
    end
  end

  describe 'GET /cart with product_id param' do
    it 'returns the most recent cart that has items when no params' do
      product_a = create(:product, price: 12.0)
      product_b = create(:product, price: 8.0)
      older_cart = create(:shopping_cart)
      create(:cart_item, cart: older_cart, product: product_a, quantity: 1)
      recent_cart = create(:shopping_cart)
      create(:cart_item, cart: recent_cart, product: product_b, quantity: 1)

      get '/cart', as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['id']).to eq(recent_cart.id)
    end
  end

  describe 'POST /cart with invalid cart_id (rescue path)' do
    it 'creates a new cart when provided cart_id does not exist' do
      post '/cart', params: { cart_id: 999_999 }, as: :json
      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json['id']).to be_present
    end
  end

  describe 'GET /cart selects last created cart without items' do
    it 'returns the most recently created cart when no carts have items' do
      create(:shopping_cart)
      recent_cart = create(:shopping_cart)

      get '/cart', as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['id']).to eq(recent_cart.id)
    end
  end

  describe 'POST /cart/add_item with invalid product' do
    it 'returns 404 when product_id does not exist' do
      post '/cart/add_item', params: { product_id: 999_999, quantity: 1 }, as: :json
      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json['error']).to eq('Product not found')
    end
  end

  describe 'Valid contracts', type: :request do
    describe 'GET /cart' do
      it 'lists products of current cart with totals' do
        product_x = create(:product, name: 'Nome do produto X', price: 7.00)
        product_y = create(:product, name: 'Nome do produto Y', price: 9.90)

        post '/cart', params: { product_id: product_x.id, quantity: 2 }, as: :json
        post '/cart', params: { product_id: product_y.id, quantity: 2 }, as: :json

        get '/cart', as: :json
        expect(response).to have_http_status(:ok)

        total_x = (product_x.price * 2).round(2)
        total_y = (product_y.price * 2).round(2)
        cart_total = (total_x + total_y).round(2)

        json = response.parsed_body
        expect(json).to match(
          a_hash_including(
            'id' => kind_of(Integer),
            'products' => [
              a_hash_including(
                'id' => product_x.id,
                'name' => product_x.name,
                'quantity' => 2,
                'unit_price' => product_x.price.to_f,
                'total_price' => total_x.to_f
              ),
              a_hash_including(
                'id' => product_y.id,
                'name' => product_y.name,
                'quantity' => 2,
                'unit_price' => product_y.price.to_f,
                'total_price' => total_y.to_f
              )
            ],
            'total_price' => cart_total.to_f
          )
        )
      end
    end

    describe 'POST /cart' do
      it 'returns payload with cart id, products list and total_price' do
        product = create(:product, name: 'Nome do produto', price: 1.99)

        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        expect(response).to have_http_status(:created)

        json = response.parsed_body
        expected_total = (product.price * 2).round(2)

        expect(json).to match(
          a_hash_including(
            'id' => kind_of(Integer),
            'products' => [
              a_hash_including(
                'id' => product.id,
                'name' => product.name,
                'quantity' => 2,
                'unit_price' => product.price.to_f,
                'total_price' => expected_total.to_f
              )
            ],
            'total_price' => expected_total.to_f
          )
        )
      end
    end

    describe 'POST /cart/add_item contract' do
      it 'updates quantity for existing product and returns full cart' do
        product = create(:product, name: 'Nome do produto X', price: 7.00)
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:ok)

        total = (product.price * 2).round(2)
        json = response.parsed_body

        expect(json).to match(
          a_hash_including(
            'id' => kind_of(Integer),
            'products' => [
              a_hash_including(
                'id' => product.id,
                'name' => product.name,
                'quantity' => 2,
                'unit_price' => product.price,
                'total_price' => total.to_f
              )
            ],
            'total_price' => total.to_f
          )
        )
      end
    end

    describe 'DELETE /cart/:product_id contract' do
      it 'removes product and returns updated products list and totals' do
        product_x = create(:product, name: 'Nome do produto X', price: 7.00)
        product_y = create(:product, name: 'Nome do produto Y', price: 9.90)

        post '/cart', params: { product_id: product_x.id, quantity: 2 }, as: :json
        post '/cart', params: { product_id: product_y.id, quantity: 1 }, as: :json

        delete "/cart/#{product_x.id}", as: :json
        expect(response).to have_http_status(:ok)

        total_y = (product_y.price * 1).round(2)
        json = response.parsed_body

        expect(json).to match(
          a_hash_including(
            'id' => kind_of(Integer),
            'products' => [
              a_hash_including(
                'id' => product_y.id,
                'name' => product_y.name,
                'quantity' => 1,
                'unit_price' => product_y.price.to_f,
                'total_price' => total_y.to_f
              )
            ],
            'total_price' => total_y.to_f
          )
        )
      end

      it 'returns 422 when product exists but is not in cart' do
        product_x = create(:product, name: 'Nome do produto X', price: 3.50)
        product_y = create(:product, name: 'Nome do produto Y', price: 2.00)

        post '/cart', params: { product_id: product_x.id, quantity: 1 }, as: :json
        delete "/cart/#{product_y.id}", as: :json
        expect(response).to have_http_status(:unprocessable_entity)

        json = response.parsed_body
        expect(json).to match(a_hash_including('errors' => kind_of(Array)))
      end

      it 'returns 404 when product_id does not exist' do
        delete '/cart/999999', as: :json
        expect(response).to have_http_status(:not_found)

        json = response.parsed_body
        expect(json).to match(a_hash_including('error' => 'Product not found'))
      end
    end
  end
end
