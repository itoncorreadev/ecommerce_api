# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    context 'when a cart_id is provided' do
      it 'marks only the specified cart as abandoned if eligible' do
        eligible = create(:cart, last_interaction_at: 4.hours.ago)
        not_eligible = create(:cart, last_interaction_at: 1.hour.ago)

        described_class.new.perform(eligible.id)

        expect(eligible.reload.abandoned?).to be true
        expect(not_eligible.reload.abandoned?).to be false
      end
    end

    context 'when no cart_id is provided' do
      it 'marks inactive carts as abandoned and keeps active carts intact' do
        inactive = create(:cart, last_interaction_at: 4.hours.ago)
        active = create(:cart, last_interaction_at: 1.hour.ago)

        described_class.new.perform

        expect(inactive.reload.abandoned?).to be true
        expect(active.reload.abandoned?).to be false
      end

      it 'removes carts abandoned for more than 7 days and keeps recent ones' do
        ancient = create(:cart, abandoned_at: 8.days.ago, last_interaction_at: 10.days.ago)
        recent = create(:cart, abandoned_at: 6.days.ago, last_interaction_at: 10.days.ago)

        described_class.new.perform

        expect(Cart.exists?(ancient.id)).to be false
        expect(Cart.exists?(recent.id)).to be true
      end
    end
  end
end
