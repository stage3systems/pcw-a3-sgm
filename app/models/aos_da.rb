require 'new_relic/agent/method_tracer'
class AosDa
  include ::NewRelic::Agent::MethodTracer
  STATUSES = {
    0 => "DRAFT",
    1 => "INITIAL",
    3 => "CLOSE",
    4 => "INQUIRY",
    6 => "ARCHIVED",
  }

  def sync(revision)
    return unless [1, 3].include?(revision.disbursement.status_cd)
    api = AosApi.new(revision.tenant)
    api.save("pcwDaRevision", da_container(revision))
  end

  def da_container(revision)
    {
      "da" => da(revision),
      "currentRevision" => current_revision(revision),
      "services" => services(revision),
    }
  end

  def da(revision)
    {
      "appointmentId" => revision.disbursement.appointment_id,
      "publicationId" => revision.disbursement.publication_id,
      "nominationId" => revision.disbursement.nomination_id,
      "vesselId" => revision.disbursement.vessel.remote_id,
      "principalId" => revision.disbursement.company.remote_id,
      "portId" => revision.disbursement.port.remote_id,
      "currency" => revision.disbursement.port.currency.code,
      "createdAt" => revision.disbursement.created_at,
      "updatedAt" => revision.disbursement.updated_at,
    }
  end

  def current_revision(revision)
    {
      "status" => STATUSES[revision.disbursement.status_cd],
      "revisionNumber" => revision.number,
      "reference" => revision.reference,
      "taxExempt" => revision.tax_exempt,
      "amount" => revision.data["total"].to_f,
      "amountWithTax" => revision.compute_amount.to_f,
      "daData" => revision_data(revision),
      "createdBy" => revision.user.remote_id,
      "updatedBy" => revision.user.remote_id,
      "createdAt" => revision.created_at,
      "updatedAt" => revision.updated_at,
    }
  end

  def revision_data(revision)
    revision.data.merge({
      "cargoTypeId" => revision.cargo_type_id,
      "cargoQty" => revision.cargo_qty,
      "daysAlongside" => revision.days_alongside,
      "loadtime" => revision.loadtime,
      "tugsIn" => revision.tugs_in,
      "tugsOut" => revision.tugs_out,
      "eta" => revision.eta,
    })
  end

  def services(revision)
    service_keys(revision).map{|key| service(revision, key)}
  end

  def service_keys(revision)
    revision.descriptions.keys
  end

  def service(revision, key)
    {
      "code" => key,
      "description" => revision.descriptions[key],
      "externalReference" => nil,
      "category" => nil,
      "supplierId" => revision.supplier_aos_id(key),
      "requesterId" => nil,
      "activityCode" => revision.activity_codes[key],
      "compulsory" => revision.compulsory[key].to_i == 1,
      "overridden" => revision.overriden[key].to_i == 1,
      "disabled" => revision.disabled[key].to_i == 1,
      "amount" => revision.values[key],
      "amountWithTax" => revision.values_with_tax[key],
      "sortOrder" => service_keys(revision).index(key),
      "comment" => revision.comments[key],
      "createdAt" => revision.created_at,
      "updatedAt" => revision.updated_at,
    }
  end
  add_method_tracer :sync, 'Custom/sync'
end
