# frozen_string_literal: true

class MarkCartAsAbandonedJob
  include Sidekiq::Job

  sidekiq_options queue: :cart_maintenance

  def perform(cart_id = nil)
    if cart_id
      # Mark specific cart as abandoned
      cart = Cart.find_by(id: cart_id)
      cart&.mark_as_abandoned
    else
      # Mark all inactive carts as abandoned (run periodically)
      Cart.inactive_for(3.hours).not_abandoned.find_each(&:mark_as_abandoned)

      # Remove carts that have been abandoned for too long (e.g., 7 days)
      Cart.abandoned.where(abandoned_at: ...7.days.ago).find_each(&:remove_if_abandoned)
    end
  end
end
