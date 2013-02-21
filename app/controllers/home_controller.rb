class HomeController < ApplicationController
  def index
    @published = Estimate.where(:status_cd => Estimate.published).order("updated_at DESC")
    @drafts = Estimate.where(:status_cd => Estimate.draft).order("updated_at DESC")
  end
end
