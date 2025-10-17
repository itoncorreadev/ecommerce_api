# frozen_string_literal: true

module CartTiming
  extend ActiveSupport::Concern

  ABANDONMENT_THRESHOLD = 3.hours
  REMOVAL_THRESHOLD = 7.days

  included do
    scope :inactive_for, lambda { |value|
      threshold = calculate_threshold(value)
      where(last_interaction_at: ...threshold)
    }
  end

  class_methods do
    def calculate_threshold(value)
      if value.is_a?(ActiveSupport::Duration)
        Time.current - value
      elsif value.respond_to?(:to_time)
        value.to_time
      else
        Time.current - value.to_i
      end
    end
  end

  private

  def should_be_abandoned?
    !abandoned? && last_interaction_at < ABANDONMENT_THRESHOLD.ago
  end

  def abandoned_for_too_long?
    last_interaction_at < REMOVAL_THRESHOLD.ago
  end
end
