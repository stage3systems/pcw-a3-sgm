class HomeController < ApplicationController
  add_breadcrumb "Dashboard", :root_url
  def index
    @published = Disbursment.where(:status_cd => Disbursment.published).order("updated_at DESC")
    @drafts = Disbursment.where(:status_cd => Disbursment.draft).order("updated_at DESC")
  end
end
