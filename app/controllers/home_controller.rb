class HomeController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Dashboard", :root_url
  def index
    ports_ids = current_user.authorized_ports.pluck :id
    @drafts = Disbursement.where(
                    :status_cd => Disbursement.draft,
                    :port_id => ports_ids).order("updated_at DESC").limit(10)
    @initials = Disbursement.where(
                    :status_cd => Disbursement.initial,
                    :port_id => ports_ids).order("updated_at DESC").limit(10)
    @finals = Disbursement.where(
                    :status_cd => Disbursement.final,
                    :port_id => ports_ids).order("updated_at DESC").limit(10)
  end
end
