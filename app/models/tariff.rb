class Tariff < ActiveRecord::Base
  belongs_to :port, counter_cache: true
  belongs_to :terminal
  mount_uploader :document, TariffUploader
end
