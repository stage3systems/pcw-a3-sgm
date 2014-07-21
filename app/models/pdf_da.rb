require "prawn/table"

class PdfDA < Prawn::Document
  include FileReport
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  def initialize(disbursement, revision, root_url)
    super(page_layout: :portrait)
    @disbursement = disbursement
    @revision = revision
    @root_url = root_url
    shortcuts
    font_setup
    header
    @cell_style = {
      border_widths: [0.1, 0, 0.1, 0],
      inline_format: true,
      border_color: 'dddddd'
    }
    to_table
    from_table
    services_table
    final_figure
    move_down(72)
    stroke_line [0,y], [540,y]
    bank_details_and_conditions
  end

  def font_setup
    # setup fallback fonts for asian charsets
    font_size = 8
    font_families.update(
      "DejaVuSans" => {
        bold: Rails.root.join('fonts', 'DejaVuSans-Bold.ttf').to_s,
        normal: Rails.root.join('fonts', 'DejaVuSans.ttf').to_s })
    kai = Rails.root.join('fonts', 'gkai00mp.ttf').to_s
    font_families.update(
      "Kai" => {
          normal: { file: kai, font: "Kai" },
          bold: kai,
          italic: kai,
          bold_italic: kai})
    font "DejaVuSans"
    fallback_fonts = ["Kai"]
  end

  def title(title, subtitle)
    text title,
         size: 20, style: :bold,
         align: :left, valign: :center
    if subtitle
      text "\n#{subtitle}",
           size: 10, style: :bold,
           alight: :left, valign: :center
    end
  end

  def header
    # title and logo
    fill_color = '000000'
    logo_path = Rails.root.join('app', 'assets', 'images',
                                ProformaDA::Application.config.tenant_da_logo)
    bounding_box([0, 720], width: 540, height: 160) do
      if @disbursement.draft?
        title("DRAFT PROFORMA DISBURSEMENT", nil)
      elsif @disbursement.initial?
        title("PROFORMA DISBURSEMENT", "Sent prior to vessel arrival")
      elsif @disbursement.close?
        title("FINAL CLOSE ESTIMATE", "Sent after vessel sailing")
      end
      image logo_path, width: 60, position: :right, vposition: :center
    end
  end

  def to_table
    bounding_box([0, 560], width: 270, height: 300) do
      fill_color = '123123'
      data = [
        ['<b>To</b>', "<b>#{@revision.data['company_name']}</b>\n#{@revision.data['company_email']}"],
        ['<b>Reference</b>', @revision.reference],
        ['<b>Issued</b>', I18n.l(@revision.updated_at.to_date)],
        ['<b>Vessel<b>', "#{@revision.data['vessel_name']}\n<font size=\"5\">(GRT: #{@revision.data["vessel_grt"]} | NRT: #{@revision.data["vessel_nrt"]} | DWT: #{@revision.data["vessel_dwt"]} | LOA: #{@revision.data["vessel_loa"]})</font>"]
      ]
      unless @revision.voyage_number.blank?
        data += [
          ['<b>Voyage Number</b>', @revision.voyage_number]
        ]
      end
      data += [
        ['<b>Port</b>', @disbursement.port.name],
        ['<b>Cargo Type</b>', (@revision.cargo_type.subsubtype rescue "N/A")],
        ['<b>Cargo Quantity</b>', @revision.cargo_qty],
        ['<b>Load Time</b>', "#{@revision.loadtime} hours"],
        ['<b>Tugs</b>', "#{@revision.tugs_in} In - #{@revision.tugs_out} Out"]
      ]
      table data, cell_style: @cell_style, column_widths: [70, 200]
    end
  end

  def from_table
    bounding_box([315, 560], width: 225, height: 300) do
      data = [
        ['<b>From</b>', "<b>#{@revision.data['office_name']||@revision.data['from_name']}</b>\n#{@revision.data['office_address1']||@revision.data['from_address1']}\n#{@revision.data['office_address2']||@revision.data['from_address2']}\n#{@revision.data['office_address3']}#{ "\n" unless @revision.data['office_address3'].blank? }#{@revision.email}"]
      ]
      table data, cell_style: @cell_style, column_widths: [70, 155]
    end
  end

  def services_table_header
    [
      {:content => "<b>Item</b>"},
      {content: "<b>Amount (#{@currency_code})</b>",
       align: :right},
      {content: "<b>Amount (#{@currency_code}) Including Taxes</b>",
       align: :right},
    ]
  end

  def service_data_for(f)
    desc = @revision.descriptions[f]
    if @revision.comments and @revision.comments[f] and @revision.comments[f] != ''
      desc += " <font size=\"5\">#{@revision.comments[f]}</font>"
    end
    [
      desc,
      {content: number_to_currency(nan_to_zero(@revision.values[f]), unit: ""),
       align: :right},
      {content: number_to_currency(nan_to_zero(@revision.values_with_tax[f]), unit: ""),
       align: :right}
    ]
  end

  def services_table_footer
    [
      '<b>Total</b>',
      {content: "<b>#{@total}<b>",
       align: :right},
      {content: "<b><font size=\"12\">#{@total_with_tax}</font></b>",
       align: :right}
    ]
  end

  def services_table
    services_data = [services_table_header]
    # real service data
    @revision.field_keys.each do |f|
      next if @revision.disabled[f] == "1"
      services_data << service_data_for(f)
    end
    # totals
    services_data << services_table_footer

    # Remove tax included column if needed
    column_widths = @revision.tax_exempt? ? [315, 225] : [180, 135, 225]
    if @revision.tax_exempt?
      services_data = services_data.map {|d| d.slice(0,2)}
    end

    # Draw the service table
    y = 340
    table = make_table(services_data,
               cell_style: {border_widths: [0, 0, 0.1, 0],
                            inline_format: true,
                            border_color: 'bbbbbb'},
               header: true,
               column_widths: column_widths) do |table|
      table.style(table.row(0),
                  border_color: "000000",
                  border_widths: [0, 0, 0.5, 0])
      table.style(table.row(-1),
                  border_color: "000000",
                  border_widths: [0.5, 0, 0, 0])
    end
    table.draw
  end

  def final_figure
    column_widths = @revision.tax_exempt? ? [315, 225] : [180, 135, 225]
    estimate_amount = {
      content: "<b><font-size=\"14\">ESTIMATED<br />AMOUNT</font></b>",
      align: :right
    }
    data = if @revision.tax_exempt?
        [
          estimate_amount,
          { content: "<b><font-size=\"24\">#{@total} </font>"+
                     "<font-size=\"12\">#{@currency_code}</font></b>",
            align: :right,
            valign: :center}
        ]
      else
        [
          " ",
          estimate_amount,
          { content: "<b><font-size=\"24\">#{@total_with_tax} </font>"+
                     "<font-size=\"12\">#{@currency_code}</font></b>",
            align: :right,
            valign: :center}
        ]
      end
    table = make_table([data],
               cell_style: {inline_format: true,
                            border_widths: [0, 0, 0, 0],
                            border_color: 'ffffff'},
               header: false,
               column_widths: column_widths) do |table|
      table.style(table.row(0).column(-2),
                  border_color: "ffffff",
                  border_widths: [0, 0, 0, 0])
      table.style(table.row(0).column(-1),
                  border_color: "000000",
                  border_widths: [1, 1, 1, 1])
    end
    table.draw
  end

  def bank_details_and_conditions
    txt = <<TXT
Please remit funds at least two (2) days prior to vessels arrival to the following Bank Account:

<b>#{@revision.data['bank_name']}</b>
<b>#{@revision.data['bank_address1']}</b>
<b>#{@revision.data['bank_address2']}</b>

<b>SWIFT Code: #{@revision.data['swift_code']}</b>
<b>BSB Number: #{@revision.data['bsb_number']}</b>
<b>A/C Number: #{@revision.data['ac_number']}</b>
<b>A/C Name: #{@revision.data['ac_name']}</b>
<b>Reference: #{@revision.data['vessel_name']}</b>

Disclaimer: this is only an estimate and any additional costs incurred for this vessel will be accounted for in our Final D/A.

This estimate is exclusive of Australian Freight Tax (AFT) which, if applicable, shall be paid by the freight beneficiary, ie owner/disponent owner.

TXT
    text txt, inline_format: true
    if @revision.tax_exempt?
      text "This estimate is exclusive of Australian Goods and Services Tax (GST).  The GST portion will be claimed back from the Australian Tax Office on your behalf.\n\n", inline_format: true
    else
      text "This estimate is inclusive of Australian Goods and Services Tax (GST).\n\n", inline_format: true
    end
    text "Note: providers of towage services in Australia use their own amended versions of the UK Standard Conditions for Towage and other Services, copies of which are available upon request or from the towage provider’s website.\n\n", inline_format: true
    text "Download the full <link href=\"#{@root_url}#{ProformaDA::Application.config.tenant_terms}\">Terms and Conditions</link>", inline_format: true
  end

end
