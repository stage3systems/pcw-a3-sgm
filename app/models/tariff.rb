class Tariff < ActiveRecord::Base
  attr_accessible :name, :document,
                  :user_id, :port_id, :terminal_id,
                  :validity_end, :validity_start
  belongs_to :port
  belongs_to :terminal
  mount_uploader :document, TariffUploader
end
