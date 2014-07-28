class FundingAgreement

  def initialize(doc)
    @document = doc
    @revision = doc.revision
    @disbursement = doc.disbursement
  end

  def conditions
    d = @revision.data
    case d['company_prefunding_type']
    when 'NONE'
      no_prefunding
    when 'PERCENT_ON_CLOSE'
      percent_on_close
    when 'PERCENT_ON_BERTH'
      if d['company_prefunding_percent'].to_i == 100
        full_funding_conditions
      else
        standard_conditions
      end
    when 'LESS_AGENCY_FEE_ON_BERTH'
      standard_conditions
    else
      default_conditions
    end
  end

  private
  def default_conditions
    "Please remit funds at least two (2) days prior to "+
    "vessels arrival to the following Bank Account:"
  end

  def no_prefunding
    "As per our Service Agreement, which is available on request, no "+
    "advance funding is required. Please arrange most prompt settlement "+
    "upon Final Disbursement Account to the following Bank Account:"
  end

  def percent_on_close
    da_status_switch(
      "Please arrange funding to the following Bank Account in due course:",
      "Please arrange remittance of advance funds to the following Bank Account:")
  end

  def full_funding_conditions
    da_status_switch(
      "Please remit in full 100% of estimated total, at least two (2) days "+
      "prior to vessel's arrival, to the following Bank Account:",
      "If yet to arrange, please remit in full 100% of estimated total to "+
      "the following Bank Account:")
  end

  def standard_conditions
    da_status_switch(
      "Please remit advance funds at least two (2) days prior to "+
      "vessel's arrival, to the following Bank Account:",
      "If yet to arrange, please remit advance funding to the "+
      "following Bank Account:")
  end

  def da_status_switch(initial, close)
    return initial if @disbursement.initial?
    return close if @disbursement.close?
    default_conditions
  end

end
