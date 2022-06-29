class DisbursementDocument
  attr_reader :disbursement, :revision
  include ActionView::Helpers::NumberHelper
  include DisbursementsHelper
  include ApplicationHelper
  include PortsHelper

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

  def office_phone
    @disbursement.office.phone if @disbursement.office
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

  def terminal_name
    @revision.data['terminal_name'] || ""
  end

  def currency_code
    @revision.data["currency_code"]
  end

  def conversion_rate
    @revision.data["target_currency_rate"] || 1
  end

  def total
    number_to_currency @revision.data['total'], unit: ""
  end

  def converted_total
    number_to_currency convert(@revision.data['total']), unit: ""
  end

  def total_with_tax
    number_to_currency @revision.data['total_with_tax'], unit: ""
  end

  def converted_total_with_tax
    number_to_currency convert(@revision.data['total_with_tax']), unit: ""
  end

  def amount_float
    @revision.tax_exempt? ? @revision.data['total'] : @revision.data['total_with_tax']
  end

  def converted_amount_float
    convert(amount_float)
  end

  def amount
    @revision.tax_exempt? ? total : total_with_tax
  end

  def converted_amount
    total_key = @revision.tax_exempt? ? 'total' : 'total_with_tax'
    converted = convert(@revision.data[total_key])
    number_to_currency converted, unit: ""
  end

  def converted_currency_code
    @revision.conversion_currency.code rescue ''
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

  def converted_value_for(k)
    as_converted_currency(@revision.values[k])
  end

  def converted_value_with_tax_for(k)
    as_converted_currency(@revision.values_with_tax[k])
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
    sgm_bank_details
  end

  def sgm_bank_details
    asian_ports = get_asian_ports()
    australian_ports = get_australian_ports()
    png_ports = get_png_ports()
    mozambique_ports = get_mozambique_ports()
    tanzania_ports = get_tanzania_ports()
    namibia_ports = get_namibia_ports()
    thai_ports = get_thai_ports()
    madagascar_ports = get_madagascar_ports()

    name = @disbursement.port.name.upcase

    if name == "MOMBASA"
      [ {style: :bold, value: "BANKING DETAILS (USD)"},
        {value: "Account Name: Sturrock Shipping Kenya Limited"},
        {value: "Bank Name: Stanbic Bank Kenya Limited"},
        {value: "Branch Name: Digo Road, Mombasa"},
        {value: "Bank Account No.: 0100000431618"},
        {value: "Swift Address: SBICKENX"},
        {value: "Correspondent Bank: JP Morgan NY Branch - New York"},
        {value: "Account No: 890778116"},
        {value: "Swift: CHASUS33"},
        {value: "IBAN No.: Same as Account No."}
      ]
    elsif thai_ports.member? name
      [
        { style: :bold, value: "BANKING DETAILS (THB)" },
        { value: "Account Holder: Sturrock Grindrod Maritime (Thailand) Co., Ltd." },
        { value: "Bankers: Bangkok Bank Public Company Limited" },
        { value: "Address: 333 Silom Road, Bangrak, Bangkok, 10500, Thailand" },
        { value: "Branch: Sathorn" },
        { value: "A/C No: 142-3-10246-4 (For THB remittance)" },
        { value: "SWIFT Code: BKKBTHBK" }
      ]
    elsif asian_ports.member? name
      [ [ {style: :bold, value: "BANKING DETAILS (SGD)"},
          {value: "Account Holder: Sturrock Grindrod Maritime Pte. Ltd."},
          {value: "Bank: Standard Chartered Bank (Singapore) Limited"},
          {value: "Bank Address: Battery Road Branch, 6 Battery Road, Singapore 049909"},
          {value: "Bank Code: 9496"},
          {value: "Account Number: 0106355465"},
          {value: "Swift Code: SCBLSG22XXX"}
        ],
        [ {style: :bold, value: "BANKING DETAILS (USD)"},
          {value: "Account Holder: Sturrock Grindrod Maritime Pte. Ltd."},
          {value: "Bank: Standard Chartered Bank (Singapore) Limited"},
          {value: "Bank Address: Battery Road Branch, 6 Battery Road, Singapore 049909"},
          {value: "Bank Code: 9496"},
          {value: "Account Number: 0104970324"},
          {value: "Swift Code: SCBLSG22XXX"}
        ]
      ]
    elsif madagascar_ports.member? name
      [ [ {style: :bold, value: "BANKING DETAILS (EURO)"},
          {value: "Account Holder: Sturrock Flex Shipping LTD"},
          {value: "Bank: B.M.O.I (Banque Malgache de l'Ocean Indien)"},
          {value: "Bank address: Angle Lt. Emmanuel Berard & Bd Joffre, Toamasina 501 - Madagascar"},
          {value: "IBAN Code: MG460000400010 021247 01101 58"},
          {value: "Account Number: 00010 021247 011 01 58"},
          {value: "Swift code: BMOIMGMG"},
          {value: "BIC: BMOIMGMGXXX"},
          {value: "Intermediary Bank details:	Natixis , Paris"},
          {value: "IBAN: FR76 3000 7999 9906 0205 5000 070"},
          {value: "Swift code: NATXFRPPXXX"},
          {value: "Address: Avenue Pierre Mendes, 75013, France"}
        ],
        [ {style: :bold, value: "BANKING DETAILS (USD)"},
          {value: "BANKING DETAILS: (USD)"},
          {value: "Account Holder: Sturrock Flex Shipping LTD"},
          {value: "Bank: B.M.O.I (Banque Malgache de l'Ocean Indien)"},
          {value: "Bank address: Angle Lt. Emmanuel Berard & Bd Joffre, Toamasina 501 - Madagascar"},
          {value: "IBAN Code: MG460000400010 021247 01102 55"},
          {value: "Account Number: 00010 021247 011 02 55"},
          {value: "Swift code: BMOIMGMG"},
          {value: "BIC: BMOIMGMGXXX"},
          {value: "Intermediary Bank details: Natixis , Paris"},
          {value: "IBAN: FR76 3000 7999 9906 0205 5000 070"},
          {value: "Swift code: NATXFRPPXXX"},
          {value: "Address: Avenue Pierre Mendes, 75013, France"}
        ]
      ]
    elsif tanzania_ports.member? name
      [ {style: :bold, value: "BANKING DETAILS (USD)"},
        {value: "Beneficiary Bank: Absa Bank Tanzania"},
        {value: "Swift Code: BARCTZTZ"},
        {value: "Beneficiary: Sturrock-Flex Shipping Ltd"},
        {value: "Account No: 001/8003848"},
        {value: "Correspondent Bank: JP Morgan Chase Bank, N.A. New York, NY"},
        {value: "Correspondent Swift Code: CHASUS33"},
      ]
    elsif mozambique_ports.member? name
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

    elsif australian_ports.member? name
      [ [ {style: :bold, value: "Banking Details (AUD)"},
          {value: "Account Holder: Sturrock Grindrod Maritime (Australia) Pty Ltd"},
          {value: "Bank: Commonwealth Bank of Australia (CBA)"},
          {value: "Bank Address: 133 Liverpool St, Sydney, NSW 2000"},
          {value: "Branch Code: 062 016"},
          {value: "Account Number: 11704980"},
          {value: "Swift Code: CTBAAU2S"}
        ],
        [ {style: :bold, value: "Banking Details (USD)"},
          {value: "Account Holder: Sturrock Grindrod Maritime Australia Pty Ltd"},
          {value: "Address: Suite 4,89-97 Jones Street, Ultimo, Sydney NSW 2007,Australia"},
          {value: "Bank: Commonwealth Bank of Australia"},
          {value: "Bank Address: 799 Pacific Highway, Chatswood NSW 2067 Australia"},
          {value: "Account Number: 1141 7739 (BSB 062-223)"},
          {value: "Swift Code: CTBAAU2S"}
        ]
      ]

  elsif png_ports.member? name
    [ [ {style: :bold, value: "Banking Details (PGK)"},
        {value: "Account Holder: Sturrock Grindrod Maritime (Australia) Pty Ltd"},
        {value: "Bank: Westpack Bank - PNG - Limited"},
        {value: "Bank Address: Waigani, Waigani Drive, Port Moresby"},
        {value: "Branch Code: 038 007"},
        {value: "Account Number: 6006402561"}
      ],
      [ {style: :bold, value: "Banking Details (USD)"},
        {value: "Account Holder: Sturrock Grindrod Maritime (Australia) Pty Ltd"},
        {value: "Bank: National Australia Bank"},
        {value: "Bank Address: 255 George Street, Sydney, NSW 2000"},
        {value: "Branch Code: 082 057"},
        {value: "Account Number: STURRUSD01"},
        {value: "Swift Code: NATAAU3302S"}
      ]
    ]

  elsif namibia_ports.member? name
    [
      {style: :bold, value: "BANKING DETAILS (NAD)"},
        {value: "Account Holder: Sturrock Grindrod Maritime (Namibia) [PTY] Ltd"},
        {value: "Bank Name: First National Bank Namibia Ltd."},
        {value: "Branch Name: Walvis Bay, Namibia"},
        {value: "Branch Code: 28-21-72"},
        {value: "Account Number: 55101754783"},
        {value: "Type: Cheque Account"},
        {value: "Swift Code: FIRNNANX"},
        {value: "Correspondent Bank: Standard Chartered Bank, New York"}
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

  def abn
    [{style: :bold, value: "ABN: 35 143148350"}, ""]
  end

  def wire_reference
    [{style: :bold, value: "Reference: #{compute_wire_reference}"}, ""]
  end

  def is_aus_or_png
    australian_ports = get_australian_ports()
    png_ports = get_png_ports()
    australian_ports.member? @disbursement.port.name or png_ports.member? @disbursement.port.name
  end

  def funding_disclaimer
    asian_ports = get_asian_ports()
    mozambique_ports = get_mozambique_ports()
    namibia_ports = get_namibia_ports()
    tanzania_ports = get_tanzania_ports()
    thai_ports = get_thai_ports()
    madagascar_ports = get_madagascar_ports()
    disclaimer = if @revision.tenant.is_sgm?
      company = "Sturrock Grindrod Maritime (Pty) Ltd"
      if @disbursement.port.name == "MOMBASA"
        company = "Sturrock Shipping (Kenya) Ltd"
      elsif thai_ports.member? @disbursement.port.name
        company = "Sturrock Grindrod Maritime (Thailand) Co., Ltd"
      elsif asian_ports.member? @disbursement.port.name
        company = "Sturrock Grindrod Maritime Pte Ltd"
      elsif namibia_ports.member? @disbursement.port.name
        company = "Sturrock Grindrod Maritime (Namibia) [PTY] Ltd"
      elsif mozambique_ports.member? @disbursement.port.name
        company = "Sturrock Grindrod Maritime [Mozambique] Lda"
      elsif tanzania_ports.member? @disbursement.port.name
        company = "Sturrock Flex Shipping Ltd"
      elsif madagascar_ports.member? @disbursement.port.name
        company = "Sturrock Flex Shipping Ltd"
      elsif is_aus_or_png
        company = "Sturrock Grindrod Maritime (Australia) Pty Ltd"
      end
      "<b>Disclaimer</b><br/>" + company +
      ", as agents only. <br>" +
      "All business transacted is undertaken subject to our Standard Trading Conditions of which a copy is available on request. All due care has been used to calculate costs for this vessel." +
      "Any additional/amended costs will be invoiced on Supplementary DA.<br>"
    else
      "Disclaimer: This is only an estimate and any additional costs "+
      "incurred for this vessel will be accounted for in our Final D/A."
    end
    [ disclaimer, ""]
  end

  def freight_tax_disclaimer
    return [] 
  end

  def tax_exempt_note
    return []
  end

  def towage_provider_note
    return []
  end

  private
  def terms_and_conditions
  end

  def convert(n)
    n.to_f*@revision.data["target_currency_rate"].to_f
  end

  def as_converted_currency(n)
    n = convert(n)
    unit = @revision.convertion_currency.unit rescue ''
    number_to_currency(nan_to_zero(n), unit: unit)
  end

  def as_currency(n, unit: "")
    number_to_currency(nan_to_zero(n), unit: unit)
  end

  def nan_to_zero(n)
    return 0 if n == 'NaN'
    return n
  end
end
