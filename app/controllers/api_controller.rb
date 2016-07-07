class ApiController < ApplicationController
  before_filter :authenticate_user!, except: [:ping]
  skip_before_filter :ensure_tenant, only: [:ping]

  def ping
    render text: "pong"
  end

  def nominations
    api = AosApi.new(current_tenant)
    render json: api.search('nomination', params.merge({'limit' => 10})).body
  end

  def nomination_details
    aos_nom = AosNomination.from_tenant_and_aos_id(current_tenant, params[:nomination_id])
    render json: aos_nom.to_json
  end

  def agency_fees
    c = current_tenant.companies.find(params[:company_id])
    q = {companyId: c.remote_id}
    p = current_tenant.ports.find(params[:port_id]) rescue nil
    q[:portId] = p.remote_id if p
    eta = Date.parse(params[:eta]) rescue nil
    if eta
      q[:dateEffectiveEnd] = eta
      q[:dateExpiresStart] = eta
    end
    fees = AosAgencyFees.find(current_tenant, q)
    render json: fees.to_json
  end

end
