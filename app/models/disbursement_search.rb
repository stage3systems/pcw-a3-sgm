class DisbursementSearch
  def initialize(params)
    @params = params
    @disbursements = Disbursement.joins(:current_revision)
    filter_port
    filter_terminal
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
  def filter_port
    port = Port.find(@params[:port_id].to_i) rescue nil
    @disbursements = @disbursements.where(port_id: port.id) if port
  end

  def filter_terminal
    terminal = Terminal.find(@params[:terminal_id].to_i) rescue nil
    @disbursements = @disbursements.where(terminal_id: terminal.id) if terminal
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
