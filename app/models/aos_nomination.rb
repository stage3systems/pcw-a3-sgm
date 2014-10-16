class AosNomination
  def self.from_aos_id(id)
    return nil unless id
    d = self.new(id)
  end

  def initialize(id)
    @id = id
    @api = AosApi.new
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
      @api.save('disbursement', c ? c.merge(j) : j)
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
    kls.find_by(remote_id: val)
  end

  def aos_nom
    @aos_nom ||= @api.find('nomination', @id)
  end

  def aos_appt
    @aos_appt ||= @api.find('appointment', aos_nom['appointmentId'])
  end
end
