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
      [
        {style: :bold, value: "By paying this proforma invoice and final invoice, the principal, or the payer, " +
        "on behalf of the principal, declares that the seagoing ship in question is effectively " +
        "used for at least 70% for navigation on the high seas and that the seagoing ship " +
        "is used entirely (100%) for commercial activities."},
        {style: :bold, value: ""},
        {style: :bold_underline, value: "Netherlands"},
        {style: :bold, value: "Account name: MariTeam Shipping Agencies"},
        {style: :bold, value: "Bank: RABOBANK, Blaak 333, 3011GB, Rotterdam"},
        {style: :bold, value: "Account number: 1207.51.836"},
        {style: :bold, value: "IBAN: NL50 RABO 01207 51 836"},
        {style: :bold, value: "Swift/BIC: RABONL2U"},
        {style: :bold, value: "Reference: #{compute_wire_reference}"},
        {style: :bold, value: ""},
        {style: :bold_underline, value: "Belgium"},
        {style: :bold, value: "Account name: MariTeam Shipping Agencies"},
        {style: :bold, value: "Bank : BNP Paribas Fortis, Antwerpen, Londenstraat 6 - B-2000 ANTWERPEN"},
        {style: :bold, value: "Account No. : 001-4819039-58"},
        {style: :bold, value: "IBAN : BE95 0014 8190 3958"},
        {style: :bold, value: "Swiftcode : GEBABEBB"} ]
    when "biehl", "biehltest", "biehlstg"
      [ 
        {style: :bold, value: "BANK OF AMERICA"},
        {style: :bold, value: "901 MAIN STREET, 10TH FLOOR"},
        {style: :bold, value: "DALLAS, TX 75202-2911"},
        {style: :bold, value: ""},
        {style: :bold, value: "ACCOUNT # 004792003683"},
        {style: :bold, value: "ACH ABA No. 111000025"},
        {style: :bold, value: "WIRE TRANSFER ABA No. 026009593"},
        {style: :bold, value: "SWIFT ID: BOFAUS3N"},
        {style: :bold, value: "FOR THE ACCOUNT OF BIEHL & CO TEXAS LLC"}, 
        {style: :bold, value: ""},
        {style: :bold, value: "PLS REFERENCE: VESSEL NAME & VOYAGE / IMO NUMBER / PORT NAME / PROFORMA ADVANCE"}
      ]
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
    when "normac" 
      [
        {style: :bold, value: "Beneficiary: Normac Shipping Limited"},
        {style: :bold, value: "Bank: Barclays Bank Plc"},
        {style: :bold, value: "Branch: Lord Street, Liverpool, U.K"},
        {style: :bold, value: "Sort Code: 20-51-01"},
        {style: :bold, value: ""},
        {style: :bold, value: "GBP Account no: 50115479"},
        {style: :bold, value: "GBP IBAN: GB04 BARC 2051 0150 1154 79"},
        {style: :bold, value: ""},
        {style: :bold, value: "USD Account no: 53680111"},
        {style: :bold, value: "USD IBAN: GB04 BARC 2051 0153 6801 11"}
      ]
    when "sgm", "sturrockgrindrod"
      sgm_bank_details
    when "wallem", "wallemgroup"
      wallem_bank_details
    when "nabsa"
      [ {style: :bold, value: "HSBC Private Bank International"},
        {style: :bold, value: "1.441, Brickell Av, 17th floor"},
        {style: :bold, value: "Miami FL 33131"},
        {style: :bold, value: "ABA Nbr.: 066010445 - Swift: HSBCUS3M"},
        {style: :bold, value: "Account: 337-289-657"},
        {style: :bold, value: "Favour: AGENCIA MARITIMA NABSA S.A."}
      ]
    when "mta"
      [ {style: :bold, value: "Beneficiary: MTA Agencia Maritima Ltda."},
        {style: :bold, value: "Bank: Santander Chile"},
        {style: :bold, value: "Tax ID: 76.902.117-5"},
        {style: :bold, value: "USD Account: 51002 93996"},
        {style: :bold, value: "Swift: BSCHCLRM"},
        {style: :bold, value: "mta@mtradeagents.com"}
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
    when "benline"
      [  {style: :bold, value: "Bank: Westpac Banking Corporation"},
         {style: :bold, value: "Bank Address: 743 Military Road, Mosman, New South Wales 2088, Australia"},
         {style: :bold, value: "Swift Code: WPACAU2S"},
         {style: :bold, value: "BSB No. 032097"},
         {style: :bold, value: "A/C No. 425166"},
         {style: :bold, value: "Currency: AUD"},
         {style: :bold, value: "Beneficiary: Ben Line Agencies (Australia) Pty Ltd"},
         {style: :bold, value: "Address: Building 1, Gateway Office Park 747 Lytton Road, Murarrie, QLD 4172, Australia"}
      ]
    when "seaforth"
      [  
        {style: :bold, value: "Banking Details (USD):"},
        {style: :bold, value: "Bank Account No.: 0100000430425"},
        {style: :bold, value: "Beneficiary Name: Seaforth Shipping Kenya Limited"},
        {style: :bold, value: "Bank Name: Stanbic Bank Kenya Limited"},
        {style: :bold, value: "Branch: Digo Road, Mombasa, Kenya"},
        {style: :bold, value: "Swift Code: SBICKENX"},
        {style: :bold, value: ""},
        {style: :bold, value: "Through Correspondent Bank:"},
        {style: :bold, value: "Bank Account No.: 04096505"},
        {style: :bold, value: "Beneficiary Name: Stanbic Bank Kenya Limited"},
        {style: :bold, value: "Bank Name: Deutsche Bank Trust Company"},
        {style: :bold, value: "Branch: New York, 280 Park Ave, New York, NY 10017, USA"},
        {style: :bold, value: "Swift Code: BKTRUS33"}
      ]
    when "fillettegreen"
      [  {style: :bold, value: "BANKING DETAILS"},
         {style: :bold, value: "For security purposes, we do not include our banking details in this document. When ready to send funding, please submit an email to accounting@fillettegreen.com requesting our banking details. Details will be forwarded under secure email. Should you receive this document with the inclusion of banking details, please contact our office immediately to verify same prior to the transmission of any funds."}
      ]
    else
      ['SWIFT Code', 'BSB Number', 'A/C Number', 'A/C Name'].map do |f|
        {style: :bold,
         value: "#{f}: #{d[f.downcase.gsub(' ','_').gsub('/', '')]}"}
      end
    end
  end

  def wallem_bank_details
    if @disbursement.port.name == "SINGAPORE"
      [
        {value: "Beneficiary: Wallem Shipping (S) Pte Ltd"},
        {value: "Beneficiary address: 991 Alexandra Road, 02-04/05, Singapore 119964"},
        {value: "The Banker: Citibank, N.A."},
        {value: "Banker's address: 8 Marina View, #21-00 Asia Square Tower 1, Singapore 018960"},
        {value: "Account no.: 0858658012 (USD) / 0858658004 (SGD)"},
        {value: "Swift code: CITISGSG "},
        {value: "Bank Code: 7214 Branch Code: 001"} 
      ]
      else
        [   
            {value: "Beneficiary: 	Wallem Shipping (Hong Kong) Limited"},
            {value: "The Banker: 	Citibank, N.A. Hong Kong Branch"},
            {value: "Banker's address: 	3 Garden Road, Central, Hong Kong"},
            {value: "Account no.: 	006-391-62341324 (USD)"},
            {value: "Account no.: 	006-391-62341170 (HKD)"},
            {value: "Swift Code: 	CITIHKHXXXX"}
        ]
    end
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
    elsif thai_ports.member? @disbursement.port.name
       [ {style: :bold, value: "BANKING DETAILS (THB)"},
          {value: "Beneficiary Name: Sturrock Grindrod Maritime Pte. Ltd."},
          {value: "Beneficiary Address: 46A Tras Street #02-46A Singapore 078985"},
          {value: "Bank Name: DBS Bank Ltd"},
          {value: "Bank Address: 12 Marina Boulevard, DBS Asia Central, Marina Bay Financial Centre Tower 3, Singapore 018982"},
          {value: "Bank Code: 7171"},
          {value: "Account Number: 0003-037876-01-6"},
          {value: "Swift Code: DBSSSGSG"}
        ]
    elsif asian_ports.member? @disbursement.port.name
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
    elsif madagascar_ports.member? @disbursement.port.name
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
    elsif tanzania_ports.member? @disbursement.port.name
      [ {style: :bold, value: "BANKING DETAILS (USD)"},
        {value: "Beneficiary Bank: Absa Bank Tanzania"},
        {value: "Swift Code: BARCTZTZ"},
        {value: "Beneficiary: Sturrock-Flex Shipping Ltd"},
        {value: "Account No: 001/8003848"},
        {value: "Correspondent Bank: JP Morgan Chase Bank, N.A. New York, NY"},
        {value: "Correspondent Swift Code: CHASUS33"},
      ]
    elsif mozambique_ports.member? @disbursement.port.name
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

    elsif australian_ports.member? @disbursement.port.name
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

  elsif png_ports.member? @disbursement.port.name
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

  elsif namibia_ports.member? @disbursement.port.name
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
    elsif @revision.tenant.is_biehl?
      "This is only an estimate, based on current applicable tariffs. Any additional costs incurred for this vessel will be accounted for in our Final D/A."
    else
      "Disclaimer: This is only an estimate and any additional costs "+
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
