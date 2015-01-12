class ApiController < ApplicationController
  before_filter :authenticate_user!

  def nominations
    api = AosApi.new
    render json: api.search('nomination', params.merge({'limit' => 10})).body
  end

  def nomination_details
    aos_nom = AosNomination.from_aos_id(params[:nomination_id])
    render json: aos_nom.to_json
  end

  def agency_fees
    c = Company.find(params[:company_id])
    q = {companyId: c.remote_id}
    p = Port.find(params[:port_id]) rescue nil
    q[:portId] = p.remote_id if p
    eta = Date.parse(params[:eta]) rescue nil
    if eta
      q[:dateEffectiveEnd] = eta
      q[:dateExpiresStart] = eta
    end
    fees = AosAgencyFees.find(q)
    render json: fees.to_json
  end

end
