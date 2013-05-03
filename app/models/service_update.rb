class ServiceUpdate < ActiveRecord::Base
  attr_accessible :changelog, :new_code, :old_code,
                  :service_id, :user_id, :document
  belongs_to :user
  belongs_to :service
  mount_uploader :document, TariffUploader
end
