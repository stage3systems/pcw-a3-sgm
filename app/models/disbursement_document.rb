class DisbursementDocument
  attr_reader :disbursement, :revision
  include ActionView::Helpers::NumberHelper

  def initialize(disbursement, revision=nil)
    @disbursement = disbursement
    @revision = revision || disbursement.current_revision rescue nil
    @name = @disbursement.inquiry? ? "Inquiry" : "estimate" if @disbursement
  end

  def title
    ["DRAFT PROFORMA DISBURSEMENT",
     "INITIAL PROFORMA DISBURSEMENT",
     "DELETED DISBURSEMENT",
     "FINAL CLOSE ESTIMATE",
     "INQUIRY DISBURSEMENT",
     "FINAL CLOSE ESTIMATE",
     "ARCHIVED ESTIMATE"][@disbursement.status_cd] rescue "PROFORMA DISBURSEMENT"
  end

  def subtitle
    return "Sent prior to vessel arrival" if @disbursement.initial?
    return "Sent after vessel sailing" if @disbursement.close?
  end

  def company_name
    @revision.data['company_name'] || ""
  end

  def company_email
    @revision.data['company_email'] || ""
  end

  def office_email
    @revision.data['office_email'] || ProformaDA::Application.config.tenant_default_email
  end

  def issued
    I18n.l @revision.updated_at.to_date
  end

  def vessel_name
    @revision.data["vessel_name"] || ""
  end

  def vessel_specs
    specs = ['grt', 'nrt', 'dwt', 'loa'].map do |k|
      "#{k.upcase}: #{@revision.data["vessel_#{k}"]}"
    end
    "(#{specs.join(" | ")})"
  end

  def cargo_type
    (@revision.cargo_type.qualifier rescue nil) || "N/A"
  end

  def from
    @revision.data['office_name'] || @revision.data['from_name']
  end

  def office_address_lines
    lines = (1..3).map do |i|
      @revision.data["office_address#{i}"] || @revision.data["from_address#{i}"]
    end
    lines.compact
  end

  def port_name
    @revision.data['port_name'] || ""
  end

  def currency_code
    @revision.data["currency_code"]
  end

  def total
    number_to_currency @revision.data['total'], unit: ""
  end

  def total_with_tax
    number_to_currency @revision.data['total_with_tax'], unit: ""
  end

  def amount
    @revision.tax_exempt? ? total : total_with_tax
  end

  def wire_reference
    "#{@revision.data['vessel_name']} #{@revision.data['vessel_imo']} #{@disbursement.nomination_reference}"
  end

  def value_for(k)
    as_currency(@revision.values[k])
  end

  def value_with_tax_for(k)
    as_currency(@revision.values_with_tax[k])
  end

  def has_comment?(k)
    @revision.comments and @revision.comments[k] and @revision.comments[k] != ''
  end

  def comment_for(k)
    @revision.comments[k]
  end

  def description_for(k)
    @revision.descriptions[k]
  end

  def active_fields
    @revision.field_keys.select {|k| @revision.disabled[k] != "1"}
  end

  def eta
    I18n.l(@revision.eta) rescue "N/A"
  end

  def to_data
    d = [
      ['To', [{style: :bold, value: company_name},
              company_email]],
      ['Reference', @revision.reference],
      ['Issued', issued],
      ['Vessel', [vessel_name,
                  {style: :small, value: vessel_specs}]]
    ]
    d << ['Voyage Number',
          @revision.voyage_number] unless @revision.voyage_number.blank?
    d += [
      ['Port', port_name],
      ['Cargo Type', cargo_type],
      ['ETA', eta],
      ['Cargo Quantity', @revision.cargo_qty.to_s],
      ['Load/Discharge', "#{@revision.loadtime} hours"],
      ['Tugs', "#{@revision.tugs_in} In - #{@revision.tugs_out} Out"]
    ]
  end

  def from_data
    data = office_address_lines
    data.unshift({style: :bold, value: from})
    data << office_email
    [
      ['From', data]
    ]
  end

  def funding_data(mail=false)
    d = [funding_disclaimer,
         freight_tax_disclaimer,
         tax_exempt_note]
    d << towage_provider_note unless mail
    d.unshift(prefunding,
              bank_details,
              bank_account_details) unless @disbursement.inquiry?
    d.reduce(:concat)
  end

  private
  def prefunding
    [
      FundingAgreement.new(self).conditions,
      ""
    ]
  end

  def bank_details
    d = @revision.data
    details = ['bank_name', 'bank_address1', 'bank_address2'].map do |f|
      {style: :bold, value: d[f]}
    end
    details << ""
  end

  def bank_account_details
    d = @revision.data
    details = ['SWIFT Code', 'BSB Number', 'A/C Number', 'A/C Name'].map do |f|
      {style: :bold,
       value: "#{f}: #{d[f.downcase.gsub(' ','_').gsub('/', '')]}"}
    end
    details += [
      {style: :bold, value: "Reference: #{wire_reference}"},
      ""
    ]
  end

  def funding_disclaimer
    disclaimer = if @disbursement.inquiry?
      "Disclaimer: Please note that this is an Inquiry only, and whilst "+
      "Monson Agencies Australia take every care to ensure that the figures "+
      "and information contained in the Inquiry are as accurate as possible, "+
      "the actual Proforma Estimate may, and often does, for various reasons "+
      "beyond our control, vary from the Inquiry"
    else
      "Disclaimer: this is only an estimate and any additional costs "+
      "incurred for this vessel will be accounted for in our Final D/A."
    end
    [ disclaimer, ""]
  end

  def freight_tax_disclaimer
    [
      "This #{@name} is exclusive of Australian Freight Tax (AFT) which, "+
      "if applicable, shall be paid by the freight beneficiary, "+
      "ie owner/disponent owner.",
      ""
    ]
  end

  def tax_exempt_note
    return [] unless @revision.tax_exempt?
    [
      "This #{@name} is exclusive of the Australian Goods "+
      "and Services Tax (GST).",
      ""
    ]
  end

  def towage_provider_note
    [
      "Note: providers of towage services in Australia use their own amended "+
      "versions of the UK Standard Conditions for Towage and other Services, "+
      "copies of which are available upon request or from the towage "+
      "provider's website.",
      ""
    ]
  end

  def terms_and_conditions
  end

  def as_currency(n, unit: "")
    number_to_currency(nan_to_zero(n), unit: unit)
  end

  def nan_to_zero(n)
    return 0 if n == 'NaN'
    return n
  end
end
