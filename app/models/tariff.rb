class Tariff < ActiveRecord::Base
  belongs_to :port, counter_cache: true
  belongs_to :terminal
  belongs_to :user
  mount_uploader :document, TariffUploader
end
