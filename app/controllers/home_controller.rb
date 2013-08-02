class HomeController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Dashboard", :root_url
  def index
    ports_ids = current_user.authorized_ports.pluck :id
    @published = Disbursment.where(
                    :status_cd => Disbursment.published,
                    :port_id => ports_ids).order("updated_at DESC")
    @drafts = Disbursment.where(
                    :status_cd => Disbursment.draft,
                    :port_id => ports_ids).order("updated_at DESC")
  end
end
