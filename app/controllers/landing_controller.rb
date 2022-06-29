class LandingController < ApplicationController
  layout "landing"
  skip_before_filter :ensure_tenant

  def index
    @title = "Port Cost Watch"
  end
end
