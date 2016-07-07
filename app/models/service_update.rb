class ServiceUpdate < ActiveRecord::Base
  belongs_to :user
  belongs_to :service
  belongs_to :tenant
  mount_uploader :document, TariffUploader
end
