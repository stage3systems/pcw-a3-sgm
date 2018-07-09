class DisbursementDocument
  attr_reader :disbursement, :revision
  include ActionView::Helpers::NumberHelper
  include DisbursementsHelper
  include ApplicationHelper

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
    @revision.data['office_email'] || @revision.tenant.default_email
  end

  def issued
    I18n.l @revision.updated_at.to_date
  end

  def logo
    if @disbursement.tenant.is_sgm? and ["DAR ES SALAAM", "MTWARA", "TANGA", "ZANZIBAR"].member? @disbursement.port.name
      return "logo_sgm2.png"
    end
    @disbursement.tenant.logo
  end

  def terms_url(root)
    @disbursement.tenant.terms_url(root)
  end

  def tenant_full_name
    @disbursement.tenant.full_name
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

  def compute_wire_reference
    [ @revision.data['vessel_name'],
      (@revision.data['vessel_imo'] unless @disbursement.tenant.is_sgm?),
      @disbursement.nomination_reference
    ].compact.join(" ")
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
      ['Tugs', "#{@revision.tugs_in} In - #{@revision.tugs_out} Out"],
      ['Days Alongside', "#{@revision.days_alongside}"]
    ]
  end

  def from_data
    data = office_address_lines
    data.unshift({style: :bold, value: from})
    data << office_email
    data << @disbursement.office.phone if @disbursement.office
    data << "Contact: #{@disbursement.user.first_name} #{@disbursement.user.last_name}"
    [
      ['From', data]
    ]
  end

  def prefunding
    return [] if @disbursement.inquiry?
    txt = FundingAgreement.new(self).conditions
    return [] if txt.blank?
    [txt, ""]
  end

  def bank_details
    d = @revision.data
    details = ['bank_name', 'bank_address1', 'bank_address2'].map do |f|
      {style: :bold, value: d[f]} if d[f]
    end
    details = details.compact
    return [] if details.empty?
    details << ""
  end

  def bank_account_details
    d = @revision.data
    case @revision.tenant.customer_name

    when "mariteam"
      [ {style: :bold, value: "Netherlands"},
        {style: :bold, value: "Account name: MariTeam Shipping Agencies"},
        {style: :bold, value: "Account number: 1207.51.836"},
        {style: :bold, value: "IBAN: NL50 RABO 01207 51 836"},
        {style: :bold, value: "Swift/BIC: RABONL2U"},
        {style: :bold, value: ""},
        {style: :bold, value: "Belgium"},
        {style: :bold, value: "Account name: MariTeam Shipping Agencies"},
        {style: :bold, value: "Bank : BNP Paribas Fortis, Antwerpen, Londenstraat 6 - B-2000 ANTWERPEN"},
        {style: :bold, value: "Account No. : 001-4819039-58"},
        {style: :bold, value: "IBAN : BE95 0014 8190 3958"},
        {style: :bold, value: "Swiftcode : GEBABEBB"} ]
    when "biehl"
      [ {style: :bold, value: "BANK OF AMERICA"},
        {style: :bold, value: "901 MAIN STREET, 10TH FLOOR"},
        {style: :bold, value: "DALLAS, TX 75202-2911"},
        {style: :bold, value: ""},
        {style: :bold, value: "ACCOUNT # 004792003683"},
        {style: :bold, value: "ACH ABA No. 111000025"},
        {style: :bold, value: "WIRE TRANSFER ABA No. 026009593"},
        {style: :bold, value: "SWIFT ID: BOFAUS3N"},
        {style: :bold, value: "FOR THE ACCOUNT OF BIEHL & CO"},
        {style: :bold, value: ""},
        {style: :bold, value: "PLS REFERENCE: VESSEL NAME & VOYAGE / IMO NUMBER / PORT NAME / PROFORMA ADVANCE"} ]
    when "casper"
      [ {style: :bold, value: "Account Name: Casper Shipping Limited"},
        {style: :bold, value: "Sort Code: 60/08/46"},
        {style: :bold, value: "BIC Code: NWBKGB2L"},
        {style: :bold, value: "GBP Account Number: 68645570"},
        {style: :bold, value: "IBAN number (GBP): GB11Nwbk60084668645570"},
        {style: :bold, value: "VAT Nr: 546807127"}
      ]
    when "transmarine"
      [ {style: :bold, value: "Bank of America, Long Beach Branch No. 1457"},
        {style: :bold, value: "150 Long Beach Blvd."},
        {style: :bold, value: "Long Beach, CA 90802"},
        {style: :bold, value: "Acct no. 14578-03336"},
        {style: :bold, value: "ABA NO. 0260-0959-3"},
        {style: :bold, value: "SWIFT: BOFAUS3N"},
        {style: :bold, value: "CHIPS: 0959"},
        {style: :bold, value: ""},
        {style: :bold, value: "Beneficiary:"},
        {style: :bold, value: "TRANSMARINE NAVIGATION CORPORATION"},
        {style: :bold, value: "SUITE 500"},
        {style: :bold, value: "301 EAST OCEAN BOULEVARD"},
        {style: :bold, value: "LONG BEACH"},
        {style: :bold, value: "CALIFORNIA 90802 4828 USA"}
      ]
    when "sgm", "sturrockgrindrod"
      sgm_bank_details
    when "nabsa"
      [ {style: :bold, value: "HSBC Private Bank International"},
        {style: :bold, value: "1.441, Brickell Av, 17th floor"},
        {style: :bold, value: "Miami FL 33131"},
        {style: :bold, value: "ABA Nbr.: 066010445 - Swift: HSBCUS3M"},
        {style: :bold, value: "Account: 337-289-657"},
        {style: :bold, value: "Favour: AGENCIA MARITIMA NABSA S.A."}
      ]
    when "marval"
      [  {style: :bold, value: "BENEFICIARY BANK: CITIBANK N.A."},
         {style: :bold, value: "666 5TH AVENUE, 7TH, FLOOR"},
         {style: :bold, value: "NY, NY10103"},
         {style: :bold, value: "ABA: 021000089"},
         {style: :bold, value: "SWIFT CODE: CITIUS33"},
         {style: :bold, value: "BENEFICIARY ACCT NBR: 36893146"},
         {style: :bold, value: "BENEFICIARY FULL NAME: MARITIMA VALPARAISO CHILE SA."}
      ]
    else
      ['SWIFT Code', 'BSB Number', 'A/C Number', 'A/C Name'].map do |f|
        {style: :bold,
         value: "#{f}: #{d[f.downcase.gsub(' ','_').gsub('/', '')]}"}
      end
    end
  end

  def sgm_bank_details
    if @disbursement.port.name == "MOMBASA"
      [ {style: :bold, value: "BANKING DETAILS (USD)"},
        {value: "Account Name: Sturrock Shipping Kenya Limited"},
        {value: "Bank Name: Stanbic Bank Kenya Limited"},
        {value: "Branch Name: Digo Road, Mombasa"},
        {value: "Bank Account No.: 0100000431618"},
        {value: "Swift Address: SBICKENX"},
        {value: "Correspondent Bank: Deutsche Bank Trust Company Americas - New York"},
        {value: "Account No: 04096505"},
        {value: "Swift: BKTRUS 33"}
      ]
    elsif ["SEMARANG", "SUNGAI", "PAKNING", "CILACAP",
           "JAKARTA SURABAYA", "LUOJING", "ZHOUSHAN",
           "RIZHAO", "HAINAN", "LANQIAO", "SINGAPORE"].member? @disbursement.port.name
      [ [ {style: :bold, value: "BANKING DETAILS (SGD)"},
          {value: "Account Holder: Sturrock Grindrod Maritime Pte. Ltd."},
          {value: "Bank: Standard Chartered"},
          {value: "Bank Address: Battery Road Branch, 6 Battery Road, Singapore 049909"},
          {value: "Bank Code: 7144"},
          {value: "Account Number: 0106355465"},
          {value: "Swift Code: SCBLSGSG"}
        ],
        [ {style: :bold, value: "BANKING DETAILS (USD)"},
          {value: "Account Holder: Sturrock Grindrod Maritime Pte. Ltd."},
          {value: "Bank: Standard Chartered"},
          {value: "Bank Address: Battery Road Branch, 6 Battery Road, Singapore 049909"},
          {value: "Bank Code: 7144"},
          {value: "Account Number: 0104970324"},
          {value: "Swift Code: SCBLSGSG"}
        ]
      ]
    elsif ["DAR ES SALAAM", "MTWARA", "TANGA", "ZANZIBAR"].member? @disbursement.port.name
      [ {style: :bold, value: "BANKING DETAILS (USD)"},
        {value: "Beneficiary Bank: Barclays Bank Tanzania Limited, TDFL Building Ohio Street, Dar Es Salaam, Tanzania"},
        {value: "Swift Code: BARCTZTZ"},
        {value: "Beneficiary: Sturrock Flex Shipping Ltd"},
        {value: "Account No: 8003848"},
        {value: "Correspondent Bank: JP Morgan Chase Bank, N.A. New York, NY"},
        {value: "Swift Code: CHASUS33"}
      ]
    elsif ["MAPUTO", "MATOLA", "BEIRA", "NACALA", "PEMBA"].member? @disbursement.port.name
      [ [ {style: :bold, value: "Banking Details (MZN)"},
          {value: "Account Holder: Sturrock Grindrod Maritime [Mozambique] Lda"},
          {value: "Bank: Standard Bank S.A.R.L"},
          {value: "Bank Address: Praça 25 De Junho, No. 1"},
          {value: "Branch Code: Main Branch - Maputo - No. 1"},
          {value: "Account Number: 1081847971006"},
          {value: "Swift Code: SBICMZMX"}
        ],
        [ {style: :bold, value: "Banking Details (USD)"},
          {value: "Account Holder: Sturrock Grindrod Maritime [Mozambique] Lda"},
          {value: "Bank: Standard Bank S.A.R.L"},
          {value: "Bank Address: Praça 25 De Junho, No. 1"},
          {value: "Branch Code: Main Branch - Maputo - No. 1"},
          {value: "Account Number: 1088053251003"},
          {value: "Swift Code: SBICMZMX"}
        ]
      ]
    else
      [ [ {style: :bold, value: "BANKING DETAILS (ZAR)"},
          {value: "Account Holder: Sturrock Grindrod Maritime (Pty) Ltd"},
          {value: "Bank: Rand Merchant Bank"},
          {value: "Bank Address: Acacia House, 2 Kikembe Drive, Umhlanga Rocks, 4320, South Africa"},
          {value: "Branch Code: 223626"},
          {value: "Account Number: 62380786940"},
          {value: "Swift Code: FIRNZAJJ"},
          {value: ""} ],
        [ {style: :bold, value: "BANKING DETAILS (USD)"},
          {value: "Account Holder: Sturrock Grindrod Maritime (Pty) Ltd"},
          {value: "Bank: Rand Merchant Bank"},
          {value: "Bank Address: Acacia House, 2 Kikembe Drive, Umhlanga Rocks, 4320, South Africa"},
          {value: "Branch Code: 223626"},
          {value: "Account Number: 0292842"},
          {value: "Swift Code: FIRNZAJJ"},
          {value: ""}
        ]
      ]
    end
  end

  def wire_reference
    [{style: :bold, value: "Reference: #{compute_wire_reference}"}, ""]
  end

  def funding_disclaimer
    disclaimer = if @revision.tenant.is_monson? and @disbursement.inquiry?
      "Disclaimer: Please note that this is an Inquiry only, and whilst "+
      "Monson Agencies Australia take every care to ensure that the figures "+
      "and information contained in the Inquiry are as accurate as possible, "+
      "the actual Proforma Estimate may, and often does, for various reasons "+
      "beyond our control, vary from the Inquiry"
    elsif @revision.tenant.is_sgm?
      company = "Sturrock Grindrod Maritime (Pty) Ltd"
      if @disbursement.port.name == "MOMBASA"
        company = "Sturrock Shipping (Kenya) Ltd"
      elsif ["SEMARANG", "SUNGAI", "PAKNING", "CILACAP",
             "JAKARTA SURABAYA", "LUOJING", "ZHOUSHAN",
             "RIZHAO", "HAINAN", "LANQIAO", "SINGAPORE"].member? @disbursement.port.name
        company = "Sturrock Grindrod Maritime Pte Ltd"
      elsif ["MAPUTO", "MATOLA", "BEIRA", "NACALA", "PEMBA"].member? @disbursement.port.name
        company = "Sturrock Grindrod Maritime [Mozambique] Lda"
      elsif ["DAR ES SALAAM", "MTWARA", "TANGA", "ZANZIBAR"].member? @disbursement.port.name
        company = "Sturrock Flex Shipping Ltd"
      end
      "<b>Disclaimer</b><br/>" + company +
      ", as agents only. <br>" +
      "All business transacted is undertaken subject to our Standard Trading Conditions of which a copy is available on request. All due care has been used to calculate costs for this vessel." +
      "Any additional/amended costs will be invoiced on Supplementary DA.<br>"
    else
      "Disclaimer: this is only an estimate and any additional costs "+
      "incurred for this vessel will be accounted for in our Final D/A."
    end
    [ disclaimer, ""]
  end

  def freight_tax_disclaimer
    return [] unless @revision.tenant.is_monson?
    [
      "This #{@name} is exclusive of Australian Freight Tax (AFT) which, "+
      "if applicable, shall be paid by the freight beneficiary, "+
      "ie owner/disponent owner.",
      ""
    ]
  end

  def tax_exempt_note
    return [] unless @revision.tenant.is_monson?
    return [] unless @revision.tax_exempt?
    [
      "This #{@name} is exclusive of the Australian Goods "+
      "and Services Tax (GST).",
      ""
    ]
  end

  def towage_provider_note
    return [] unless @revision.tenant.is_monson?
    [
      "Note: providers of towage services in Australia use their own amended "+
      "versions of the UK Standard Conditions for Towage and other Services, "+
      "copies of which are available upon request or from the towage "+
      "provider's website.",
      ""
    ]
  end

  private
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
