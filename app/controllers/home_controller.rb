class HomeController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Dashboard", :root_url
  def index
    @title = "Dashboard"
    ports_ids = current_user.authorized_ports.pluck :id
    @drafts = current_tenant.disbursements.where(
                    status_cd: Disbursement.statuses[:draft],
                    port_id: ports_ids).order("updated_at DESC").limit(10)
    @inquiries = current_tenant.disbursements.where(
                    status_cd: Disbursement.statuses[:inquiry],
                    port_id: ports_ids).order("updated_at DESC").limit(10)
    @initials = current_tenant.disbursements.where(
                    status_cd: Disbursement.statuses[:initial],
                    port_id: ports_ids).order("updated_at DESC").limit(10)
    @closes = current_tenant.disbursements.where(
                    status_cd: Disbursement.statuses[:close],
                    port_id: ports_ids).order("updated_at DESC").limit(10)
  end
end
