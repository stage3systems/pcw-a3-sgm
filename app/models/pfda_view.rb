class PfdaView < ActiveRecord::Base
  attr_accessible :browser, :browser_version, :disbursement_revision_id, :ip, :pdf, :user_agent
  belongs_to :disbursement_revision
end
