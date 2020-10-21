require 'new_relic/agent/method_tracer'
class AosNomination
  include ::NewRelic::Agent::MethodTracer
  def self.from_tenant_and_aos_id(tenant, id)
    return nil unless id
    self.new(tenant, id)
  end

  def initialize(tenant, id)
    config = Rails.application.config.x.sns
    @id = id
    @tenant = tenant
    @api = AosApi.new(tenant)
    if Rails.env.test?
      @syncQueue = AosSyncQueueNull.new(tenant)
    else
      @syncQueue = AosSyncQueue.new(tenant, config['sns_topic'], config['region'])
    end
  end

  def vessel
    get_entity(Vessel)
  end

  def port
    get_entity(Port)
  end

  def company
    get_entity(Company, 'principalId')
  end

  def appointment_id
    aos_nom['appointmentId']
  end

  def nomination_reference
    "#{aos_appt['fileNumber']}-#{aos_nom['nominationNumber']}"
  end

  def charges
    @charges ||= get_charges
  end

  def get_charges
    items = {}
    @api.each('disbursement', {nominationId: @id}) do |c|
      items[c['code']] = c
    end
    items
  end

  def sync_revision(revision)
    keys = revision.fields.keys
    base = revision.disbursement.charge_base
    keys.each do |k|
      c = charges[k]
      j = base.merge(revision.charge_to_json(k))
      @syncQueue.publish('disbursement', c ? c.merge(j) : j)
    end
    delete_missing(keys)
  end

  def delete_missing(keys)
    (charges.keys-keys).each do |k|
      @api.delete('disbursement', charges[k]['id'])
    end
  end

  def to_json
    r = {nomination_reference: self.nomination_reference}
    ['port', 'company', 'vessel'].each do |name|
      entity = self.send(name)
      r.merge!({"#{name}_id" => entity.id, "#{name}_name" => entity.name}) if entity
    end
    r
  end

  private
  def get_entity(kls, field=nil)
    field ||= "#{kls.name.downcase}Id"
    val = aos_nom[field]
    return unless val
    kls.find_by(tenant_id: @tenant.id, remote_id: val)
  end

  def aos_nom
    @aos_nom ||= @api.find('nomination', @id)
  end

  def aos_appt
    @aos_appt ||= @api.find('appointment', appointment_id)
  end

  add_method_tracer :sync_revision, 'Custom/sync_revision'
end
