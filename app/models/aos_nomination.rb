class AosNomination
  def self.from_aos_id(id)
    return nil unless id
    d = self.new(id)
  end

  def initialize(id)
    api = AosApi.new
    @aos_nom = api.find('nomination', id)
    @aos_appt = api.find('appointment', @aos_nom['appointmentId'])
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
    @aos_nom['appointmentId']
  end

  def nomination_reference
    "#{@aos_appt['fileNumber']}-#{@aos_nom['nominationNumber']}"
  end

  private
  def get_entity(kls, field=nil)
    field ||= "#{kls.name.downcase}Id"
    val = @aos_nom[field]
    return unless val
    kls.find_by(remote_id: val)
  end
  
end
