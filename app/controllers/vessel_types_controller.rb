class VesselTypesController < BaseController
  before_filter :authenticate_user!

  def vessel_subtype
    types = VesselType.where(vessel_type: params[:vessel_type]).where.not(vessel_subtype: nil).pluck(:vessel_subtype).to_json
    respond_to do |format|
      format.json { render json: types }
    end
  end
end