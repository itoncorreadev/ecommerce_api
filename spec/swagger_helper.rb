# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      components: {
        schemas: {
          Product: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: 'Product name' },
              price: { type: :number, format: :float, example: 99.9 },
              description: { type: :string, example: 'Optional description' },
              created_at: { type: :string, format: :'date-time', example: '2025-10-12T21:41:02Z' },
              updated_at: { type: :string, format: :'date-time', example: '2025-10-12T21:41:02Z' }
            },
            required: %w[id name price]
          },
          CartItem: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: 'Product name' },
              unit_price: { type: :number, format: :float, example: 99.9 },
              quantity: { type: :integer, example: 2 },
              total_price: { type: :number, format: :float, example: 199.8 }
            },
            required: %w[id name unit_price quantity total_price]
          },
          Cart: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              products: {
                type: :array,
                items: { '$ref' => '#/components/schemas/CartItem' }
              },
              total_price: { type: :number, format: :float, example: 199.8 }
            },
            required: %w[id total_price products]
          },
          ErrorResponse: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: { type: :string },
                example: ['quantity must be greater than 0']
              },
              error: { type: :string, example: 'Product not found' }
            }
          }
        }
      },
      servers: [
        {
          url: 'http://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'localhost:3000'
            }
          }
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
