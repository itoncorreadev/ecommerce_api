# frozen_string_literal: true

class AddAbandonmentColumnsToCarts < ActiveRecord::Migration[7.1]
  def change
    add_column :carts, :abandoned_at, :datetime
    add_column :carts, :last_interaction_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }

    add_index :carts, :abandoned_at
    add_index :carts, :last_interaction_at
  end
end
