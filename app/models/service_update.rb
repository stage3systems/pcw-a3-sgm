class ServiceUpdate < ActiveRecord::Base
  include CopyCarrierwaveFile
  belongs_to :user
  belongs_to :service
  belongs_to :tenant
  mount_uploader :document, TariffUploader

  def document_from_service(original)
    copy_carrierwave_file(original, self, :document) if original.document and original.document.file and original.document.file.exists?
  end
end
