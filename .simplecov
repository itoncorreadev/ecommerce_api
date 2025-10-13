# frozen_string_literal: true

SimpleCov.minimum_coverage_by_file 100
SimpleCov.minimum_coverage 100

SimpleCov.start 'rails' do
  add_group 'Serializers', 'app/serializers'
  add_group 'Services', 'app/services'
  add_group 'Sidekiq', 'app/sidekiq'

  add_filter 'app/channels/'
  add_filter 'app/mailers/'
  add_filter 'app/jobs/'
end
