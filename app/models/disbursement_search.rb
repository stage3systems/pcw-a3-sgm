class DisbursementSearch
  def initialize(tenant, params)
    @tenant = tenant
    @params = params
    @disbursements = Disbursement.where(tenant_id: tenant.id).joins(:current_revision)
    filter_association(Port)
    filter_association(Terminal)
    filter_cargo_type
    filter_dates
    filter_vessel_name
    @count = @disbursements.count
    @disbursements = @disbursements.order('updated_at DESC')
    @page = params[:page].to_i
    @disbursements = @disbursements.offset(@page*10).limit(10)
  end

  def results
    {
      :disbursements => @disbursements,
      :count => @count,
      :page => @page+1,
      :params => @params
    }
  end

  private
  def filter_association(kls)
    id = "#{kls.name.downcase}_id".to_sym
    i = kls.find(@params[id].to_i) rescue nil
    @disbursements = @disbursements.where(id => i.id) if i
  end

  def filter_cargo_type
    cargo_type = CargoType.find(@params[:cargo_type_id].to_i) rescue nil
    @disbursements = @disbursements.where(
                      'disbursement_revisions.cargo_type_id = :ct_id',
                      ct_id: cargo_type.id) if cargo_type
  end

  def filter_dates
    start_date = Date.parse(@params[:start_date]) rescue nil
    end_date = Date.parse(@params[:end_date]) rescue nil
    @disbursements = @disbursements.where('disbursements.updated_at > :start_date', start_date: start_date) if start_date
    @disbursements = @disbursements.where('disbursements.updated_at < :end_date', end_date: end_date) if end_date
  end

  def filter_vessel_name
    @disbursements = @disbursements.where("disbursement_revisions.data -> 'vessel_name' ILIKE ?", "%#{@params[:vessel_name]}%") if @params[:vessel_name]
  end
end
