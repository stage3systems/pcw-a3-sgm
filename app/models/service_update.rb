class ServiceUpdate < ActiveRecord::Base
  belongs_to :user
  belongs_to :service
  mount_uploader :document, TariffUploader
end
