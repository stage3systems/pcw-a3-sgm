class Service < ActiveRecord::Base
  include RankedModel
  attr_accessor :changelog
  attr_accessible :user_id, :code, :item, :key,
                  :port_id, :row_order, :terminal_id, :document, :compulsory
  belongs_to :port
  belongs_to :terminal
  belongs_to :user
  has_many :service_updates
  mount_uploader :document, TariffUploader
  ranks :row_order, :with_same => [:port_id, :terminal_id]
end
