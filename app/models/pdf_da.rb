require "prawn/table"

class PdfDA < Prawn::Document

  include DisbursementsHelper
  include FileReport

  BLACK = '000000'
  WHITE = 'ffffff'
  GREY = 'bbbbbb'
  LIGHT_GREY = 'dddddd'
  NO_BORDER = [0, 0, 0, 0]
  FULL_BORDER = [1, 1, 1, 1]
  # A4
  WIDTH = 595
  HEIGHT = 842
  MARGIN = 36
  USABLE_WIDTH = WIDTH-MARGIN*2
  USABLE_HEIGHT = HEIGHT-MARGIN*2
  HEADER_HEIGHT = 120
  TO_FROM_HEIGHT = 330

  def initialize(document, root_url)
    super(page_size: 'A4', page_layout: :portrait, margin: MARGIN)
    set_context(document)
    @root_url = root_url
    font_setup
    header
    @cell_style = {
      border_widths: [1, 0, 1, 0],
      inline_format: true,
      border_color: LIGHT_GREY
    }
    @cell_style_bank_details = {
      border_widths: [0, 0, 0, 0],
      inline_format: true,
      border_color: NO_BORDER
    }
    to_table
    from_table
    services_table
    final_figure
    move_down(72)
    stroke_line [0,y], [USABLE_WIDTH,y]
    funding_details
    terms_and_conditions
  end

  private
  def font_setup
    # setup fallback fonts for asian charsets
    self.font_size = 8
    self.font_families.update(
      "DejaVuSans" => {
        bold: Rails.root.join('fonts', 'DejaVuSans-Bold.ttf').to_s,
        normal: Rails.root.join('fonts', 'DejaVuSans.ttf').to_s })
    kai = Rails.root.join('fonts', 'gkai00mp.ttf').to_s
    self.font_families.update(
      "Kai" => {
          normal: { file: kai, font: "Kai" },
          bold: kai,
          italic: kai,
          bold_italic: kai})
    self.font "DejaVuSans"
    self.fallback_fonts = ["Kai"]
  end

  def title(title, subtitle=nil)
    title_size = @disbursement.tenant.is_sgm?  ? 16 : 20
    text title,
         size: title_size, style: :bold,
         align: :left, valign: :center
    return unless subtitle
    text "\n#{subtitle}",
         size: 10, style: :bold,
         alight: :left, valign: :center
  end

  def header
    # title and logo
    self.fill_color = '000000'
    logo_path = Rails.root.join('app', 'assets', 'images',
                                @document.logo)
    bounding_box([0, HEIGHT-MARGIN],
                 width: USABLE_WIDTH, height: HEADER_HEIGHT) do
      title(@document.title, @document.subtitle)
      logo_width = @disbursement.tenant.is_sgm?  ? 120 : 60
      image logo_path, width: logo_width, position: :right, vposition: :center
    end
  end

  def make_bold(v)
    "<b>#{v}</b>"
  end

  def make_small(v)
    with_font_size(5, v)
  end

  def with_font_size(size, v)
    "<font-size=\"#{size}\">#{v}</font>"
  end

  def table_format(data)
    data.map do |h, d|
      [make_bold(h),
       format_list(d,
                   method(:make_bold),
                   method(:make_small),
                   "\n")]
    end
  end

  def to_table
    bounding_box([0, HEIGHT-MARGIN-HEADER_HEIGHT],
                 width: 262, height: TO_FROM_HEIGHT) do
      fill_color = '123123'
      table table_format(@document.to_data),
            cell_style: @cell_style,
            column_widths: [68, 194]
    end
  end

  def table_column_widths
    @revision.tax_exempt? ? [305, 218] : [174, 130, 219]
  end

  def from_table
    bounding_box([305, HEIGHT-MARGIN-HEADER_HEIGHT],
                 width: 218, height: TO_FROM_HEIGHT) do
      table table_format(@document.from_data),
            cell_style: @cell_style,
            column_widths: [68, 150]
    end
  end

  def services_table_header
    [
      '<b>Item</b>',
      {content: "<b>Amount (#{@document.currency_code})</b>",
       align: :right},
      {content: "<b>Amount (#{@document.currency_code}) Including Taxes</b>",
       align: :right}
    ]
  end

  def service_data_for(f)
    desc = @document.description_for(f)
    if @document.has_comment? f
      desc += " #{make_small(@document.comment_for(f))}"
    end
    [
      desc,
      {content: @document.value_for(f), align: :right},
      {content: @document.value_with_tax_for(f), align: :right}
    ]
  end

  def services_table_footer
    [
      '<b>Total</b>',
      {content: make_bold(@document.total),
       align: :right},
      {content: "<b><font size=\"12\">#{@document.total_with_tax}</font></b>",
       align: :right}
    ]
  end

  def services_table_data
    # real service data
    services_data = @document.active_fields.map {|f| service_data_for(f) }
    # prepend header
    services_data.unshift(services_table_header)
    # totals
    services_data << services_table_footer
    # Remove tax included column if needed
    services_data = services_data.map {|d| d.slice(0,2)} if @revision.tax_exempt?
    services_data
  end

  def services_table

    # Draw the service table
    y = USABLE_HEIGHT-HEADER_HEIGHT-TO_FROM_HEIGHT
    table = make_table(services_table_data,
               cell_style: {border_widths: [0, 0, 1, 0],
                            inline_format: true,
                            border_color: GREY},
               header: true,
               column_widths: table_column_widths) do |table|
      table.style(table.row(0),
                  border_color: BLACK,
                  border_widths: [0, 0, 1, 0])
      table.style(table.row(-1),
                  border_color: BLACK,
                  border_widths: [1, 0, 0, 0])
    end
    table.draw
  end

  def final_figure
    data = [
      {
        content: "<b><font-size=\"14\">ESTIMATED<br />AMOUNT</font></b>",
        align: :right
      },
      {
        content: "<b><font-size=\"24\">#{@document.amount}</font>"+
                 "<font-size=\"12\">#{@document.currency_code}</font></b>",
        align: :right,
        valign: :center
      }
    ]
    data.unshift(" ") unless @revision.tax_exempt?
    table = make_table([data],
               cell_style: {inline_format: true,
                            border_widths: NO_BORDER},
               header: false,
               column_widths: table_column_widths) do |table|
      row = table.row(0)
      table.style(row.column(-1),
                  border_color: BLACK,
                  border_widths: FULL_BORDER)
    end
    table.draw
  end

  def funding_details
    funding_details_item(@document.prefunding)
    funding_details_item(@document.bank_details)
    if @disbursement.tenant.is_sgm?
        details = @document.bank_account_details
        move_down(10)
        start_y = y
        bounding_box([0, start_y],
                     width: 270, height: 90) do
          funding_details_item(details[0])
        end
        y = start_y
        bounding_box([262, y],
                     width: 262, height: 90) do
          funding_details_item(details[1])
        end
    else
      funding_details_item(@document.bank_account_details)
    end
    funding_details_item(@document.wire_reference)
    funding_details_item(@document.funding_disclaimer)
    funding_details_item(@document.freight_tax_disclaimer)
    funding_details_item(@document.tax_exempt_note)
    funding_details_item(@document.towage_provider_note)
  end

  def funding_details_item(data)
    txt = quick_format_data(data)
    text txt, inline_format: true
  end

  def quick_format_data(data)
    format_list(data,
        method(:make_bold),
        method(:make_small),
        "\n")
  end

  def quick_render(formatted_data, use_draw_text = false, height = 0)
    if use_draw_text
      draw_text formatted_data, inline_format: true, :at => [0, height]
    else
      text formatted_data, inline_format: true
    end
  end

  def terms_and_conditions
    text "\nDownload the full <link href=\""+
         "#{@root_url}#{@document.terms}"+
         "\">Terms and Conditions</link>",
         inline_format: true
  end

end
