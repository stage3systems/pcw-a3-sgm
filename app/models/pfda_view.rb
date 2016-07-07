class PfdaView < ActiveRecord::Base
  belongs_to :disbursement_revision
  belongs_to :tenant

  def setup(tenant, request, browser, revision)
    self.tenant = tenant
    self.disbursement_revision = revision
    self.ip = request.remote_ip
    self.browser = browser.name
    self.browser_version = browser.version
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.pdf = false
  end

  def anonymous!
    self.pdf = false
    self.save
    increment_revision_counter :anonymous_views
  end

  def pdf!
    self.pdf = true
    self.save
    increment_revision_counter :pdf_views
  end

  private
  def increment_revision_counter(counter)
    DisbursementRevision.increment_counter counter,
                                            self.disbursement_revision_id
  end
end
