class HomeController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Dashboard", :root_url
  def index
    @title = "Dashboard"
    ports_ids = current_user.authorized_ports.pluck :id
    @drafts = Disbursement.where(
                    status_cd: Disbursement.statuses[:draft],
                    port_id: ports_ids).order("updated_at DESC").limit(10)
    @inquiries = Disbursement.where(
                    status_cd: Disbursement.statuses[:inquiry],
                    port_id: ports_ids).order("updated_at DESC").limit(10)
    @initials = Disbursement.where(
                    status_cd: Disbursement.statuses[:initial],
                    port_id: ports_ids).order("updated_at DESC").limit(10)
    @closes = Disbursement.where(
                    status_cd: Disbursement.statuses[:close],
                    port_id: ports_ids).order("updated_at DESC").limit(10)
  end
end
