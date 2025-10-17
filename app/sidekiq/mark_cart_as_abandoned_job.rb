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
      Cart.inactive_for(CartTiming::ABANDONMENT_THRESHOLD).not_abandoned.find_each(&:mark_as_abandoned)

      # Remove carts that have been abandoned for too long
      Cart.abandoned.where(abandoned_at: ...CartTiming::REMOVAL_THRESHOLD.ago).find_each(&:remove_if_abandoned)
    end
  end
end
