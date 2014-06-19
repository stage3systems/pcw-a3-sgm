class CargoTypesController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Cargo Types", :cargo_types_url

  def index
    @title = "Cargo Types"
    @cts = CargoType.all
  end

  def enabled
    if current_user.admin?
      CargoType.where('id not in (:ids) AND enabled = true',
                      ids: params[:ids]).update_all(enabled: false)
      CargoType.where(id: params[:ids],
                      enabled: false).update_all(enabled: true)
    end
    render json: {status: 'ok'}
  end
end
