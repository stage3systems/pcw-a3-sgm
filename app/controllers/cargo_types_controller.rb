class CargoTypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :ensure_admin

  add_breadcrumb "Cargo Types", :cargo_types_url

  def index
    @title = "Cargo Types"
    @cts = current_tenant.cargo_types.all
  end

  def enabled
    if current_user.admin?
      current_tenant.cargo_types.where(
        'id not in (:ids) AND enabled = true',
        ids: params[:ids]).update_all(enabled: false)
      current_tenant.cargo_types.where(
        id: params[:ids],
        enabled: false).update_all(enabled: true)
    end
    render json: {status: 'ok'}
  end
end
