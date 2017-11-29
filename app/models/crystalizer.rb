class Crystalizer
  def initialize(disbursement)
    @disbursement = disbursement
    @hash = crystalize_hash
  end

  def run
    @disbursement.port.crystalize(@hash, @disbursement.blank?)
    @disbursement.terminal.crystalize(@hash, @disbursement.blank?) if @disbursement.terminal
    crystalize_vessel
    @disbursement.company.crystalize(@hash) if @disbursement.company
    @disbursement.office.crystalize(@hash) if @disbursement.office
    @disbursement.tenant.configurations.last.crystalize(@hash)
    crystalize_agency_fees
    @hash
  end

  private
  def crystalize_hash
    {
      "data" => {},
      "fields" => {},
      "descriptions" => {},
      "codes" => {},
      "activity_codes" => {},
      "compulsory" => {},
      "hints" => {},
      "index" => 0
    }
  end

  def crystalize_vessel
    if @disbursement.tbn?
      @hash['data'].merge!({
        "vessel_name" => "TBN-#{@disbursement.company.name rescue "NoPrincipal"}",
        "vessel_dwt" => @disbursement.dwt,
        "vessel_grt" => @disbursement.grt,
        "vessel_nrt" => @disbursement.nrt,
        "vessel_loa" => @disbursement.loa,
        "vessel_sbt_certified" => @disbursement.sbt_certified,
      })
    else
      @disbursement.vessel.crystalize(@hash)
    end
  end

  def crystalize_agency_fees
    date = @disbursement.created_at.to_date
    AosAgencyFees.find(@disbursement.tenant, {
      companyId: @disbursement.company.remote_id,
      portId: @disbursement.port.remote_id,
      dateEffectiveEnd: date,
      dateExpiresStart: date
    }).each do |f|
      crystalize_fee(f)
    end if @disbursement.company
  end

  def crystalize_fee(f)
    key = "AGENCY-FEE-#{f[:id]}"
    @hash['fields'][key] = @hash['index']
    @hash['descriptions'][key] = f[:description]
    @hash['codes'][key] = f[:code]
    @hash['activity_codes'][key] = 'AFEE'
    @hash['compulsory'][key] = '0'
    @hash['hints'][key] = f[:hint]
    @hash['index'] += 1
  end
end
