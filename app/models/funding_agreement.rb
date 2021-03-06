class FundingAgreement
  include PortsHelper

  def initialize(doc)
    @document = doc
    @revision = doc.revision
    @disbursement = doc.disbursement
  end

  def conditions
    return "" if @disbursement.inquiry?
    return sgm_mozambique_conditions if is_sgm_mozambique_port()
    return "" if @revision.tenant.name.start_with? "sgm"
    return mariteam_conditions if @revision.tenant.customer_name == "mariteam"
    return generic_conditions 
    d = @revision.data
    pfpercent = d['company_prefunding_percent'].to_i
    case d['company_prefunding_type']
    when 'NONE'
      no_prefunding
    when 'PERCENT_ON_CLOSE'
      percent_on_close(pfpercent)
    when 'PERCENT_ON_BERTH'
      if pfpercent == 100
        full_funding_conditions
      else
        standard_conditions(pfpercent)
      end
    when 'LESS_AGENCY_FEE_ON_BERTH'
      minus_fee_conditions(pfpercent)
    else
      default_conditions
    end
  end

  def is_sgm_mozambique_port()
    is_sqm = @revision.tenant.name.start_with? "sgm"
    mozambique_ports = get_mozambique_ports().member? @disbursement.port.name
    is_sqm && mozambique_ports
  end

  def sgm_mozambique_conditions
    "<strong style='color: red; font-size:14px'>In light of global economic uncertainty, SGM Mozambique requires 100% prefunding prior to the vessel berthing.</strong>"
  end

  private

  def generic_conditions
    "Please remit funds days prior to vessels arrival " +
    "to the following Bank Account:"
  end

  def default_conditions
    "Please remit funds at least two (2) days prior to "+
    "vessels arrival to the following Bank Account:"
  end

  def no_prefunding
    "As per our Service Agreement, which is available on request, no "+
    "advance funding is required. Please arrange most prompt settlement "+
    "upon Final Disbursement Account to the following Bank Account:"
  end

  def percent_on_close(percent)
    da_status_switch(
      "Please arrange #{percent}% of estimated total, to the following "+
      "Bank Account in due course:",
      "Please remit at least #{percent}% of estimated total, as advance "+
      "funding, to the following Bank Account:")
  end

  def full_funding_conditions
    da_status_switch(
      "Please remit in full 100% of estimated total, at least two (2) days "+
      "prior to vessel's arrival, to the following Bank Account:",
      "If yet to arrange, please remit in full 100% of estimated total, "+
      "immediately, to the following Bank Account:")
  end

  def standard_conditions(percent)
    da_status_switch(
      "Please remit at least #{percent}% of estimated total, at least two "+
      "(2) days prior to vessel's arrival, to the following Bank Account:",
      "If yet to arrange, please remit at least #{percent}% of estimated "+
      "total, immediately, to the following Bank Account:")
  end

  def minus_fee_conditions(percent)
    da_status_switch(
      "Please remit #{percent}% of estimated total (minus agency fee), "+
      "at least two (2) days prior to vessel's arrival, to the following "+
      "Bank Account:",
      "If yet to arrange, please remit #{percent}% of estimated total, "+
      "(minus agency fee), immediately, to the following Bank Account:")
  end

  def da_status_switch(initial, close)
    return initial if @disbursement.initial?
    return close if @disbursement.close?
    default_conditions
  end

end
