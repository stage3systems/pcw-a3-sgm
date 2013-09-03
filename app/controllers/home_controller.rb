class HomeController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Dashboard", :root_url
  def index
    ports_ids = current_user.authorized_ports.pluck :id
    @published = Disbursement.where(
                    :status_cd => Disbursement.published,
                    :port_id => ports_ids).order("updated_at DESC").limit(10)
    @drafts = Disbursement.where(
                    :status_cd => Disbursement.draft,
                    :port_id => ports_ids).order("updated_at DESC").limit(10)
  end
end
