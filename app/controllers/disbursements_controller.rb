# encoding: utf-8
class DisbursementsController < ApplicationController
  before_filter :authenticate_user!, :except => :published
  add_breadcrumb "Proforma Disbursements", :disbursements_url
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  # GET /disbursements
  # GET /disbursements.json
  def index
    @disbursements_grid = initialize_grid(Disbursement.where(
          port_id: current_user.authorized_ports.pluck(:id)
        ),
        joins: [:port, :company, :vessel, :current_revision],
        order: 'disbursement_revisions.updated_at',
        order_direction: 'desc',
        custom_order: {
          'disbursements.current_revision_id' => 'current_revision.updated_at',
          'disbursements.port_id' => 'port.name',
          'disbursements.company_id' => 'company.name'
        },
        :per_page => 10)
    @disbursements = []
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @disbursements }
    end
  end

  def search
    port = Port.find(params[:port_id].to_i) rescue nil
    terminal = Terminal.find(params[:terminal_id].to_i) rescue nil
    cargo_type = CargoType.find(params[:cargo_type_id].to_i) rescue nil
    start_date = Date.parse(params[:start_date]) rescue nil
    end_date = Date.parse(params[:end_date]) rescue nil
    p = {}
    p[:port_id] = port.id if port
    p[:terminal_id] = terminal.id if terminal
    @disbursements = Disbursement.joins(:current_revision).where(p)
    @disbursements = @disbursements.where('disbursements.updated_at > :start_date', start_date: start_date) if start_date
    @disbursements = @disbursements.where('disbursements.updated_at < :end_date', end_date: end_date) if end_date
    @disbursements = @disbursements.where("disbursement_revisions.data -> 'vessel_name' ILIKE ?", "%#{params[:vessel_name]}%") if params[:vessel_name]
    count = @disbursements.count
    @disbursements = @disbursements.order('updated_at DESC')
    page = params[:page].to_i
    @disbursements = @disbursements.offset(page*10).limit(10)
    respond_to do |format|
      format.json {
        render json: {
          :disbursements => @disbursements,
          :count => count,
          :page => page+1,
          :params => params
        }
      }
    end
  end

  def published
    @disbursement = Disbursement.find_by_publication_id(params[:id])
    @revision = @disbursement.current_revision rescue nil
    pfda_view = PfdaView.new
    pfda_view.disbursement_revision_id = @revision.id rescue nil
    pfda_view.ip = request.remote_ip
    pfda_view.browser = browser.name
    pfda_view.browser_version = browser.version
    pfda_view.user_agent = request.env['HTTP_USER_AGENT']
    pfda_view.pdf = false

    respond_to do |format|
      format.html {
        if @revision and current_user.nil?
          pfda_view.save
          DisbursementRevision.increment_counter :anonymous_views, @revision.id
        end
        render layout: "published"
      }
      format.pdf {
        if @revision and current_user.nil?
          pfda_view.pdf = true
          pfda_view.save
          DisbursementRevision.increment_counter :pdf_views, @revision.id
        end
        Dir.mkdir Rails.root.join('pdfs') unless Dir.exists? Rails.root.join('pdfs')
        file = Rails.root.join 'pdfs', "#{@revision.reference}.pdf"
        unless File.exists? file
          format_pdf
          @pdf.render_file file
        end
        send_file(file, :type => "application/pdf")
      }
      format.xls {
        #@revision.increment! :xls_views if @revision and current_user.nil?
        Dir.mkdir Rails.root.join('sheets') unless Dir.exists? Rails.root.join('sheets')
        file = Rails.root.join 'sheets', "#{@revision.reference}.xls"
        unless File.exists? file
          format_xls.write file
        end
        send_file(file, :type => "application/ms-excel")
      }
    end
  end

  def print
    @disbursement = Disbursement.find(params[:id])
    @revision = @disbursement.current_revision
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    format_pdf
    send_data @pdf.render, type: "application/pdf",
              filename: "#{@revision.reference}#{ " - DRAFT" if @disbursement.draft? }.pdf"
  end


  def status
    @disbursement = Disbursement.find(params[:id])
    if ["draft", "initial", "final"].member? params[:status]
      @disbursement.send("#{params[:status]}!")
      @disbursement.save
    end

    respond_to do |format|
      format.html { redirect_to disbursements_path}
      format.json { render json: @disbursement }
    end
  end


  # GET /disbursements/1
  # GET /disbursements/1.json
  def show
    @disbursement = Disbursement.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @disbursement }
    end
  end

  # GET /disbursements/new
  # GET /disbursements/new.json
  def new
    @disbursement = Disbursement.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @disbursement }
    end
  end

  # GET /disbursements/1/edit
  def edit
    @disbursement = Disbursement.find(params[:id])
    @revision = @disbursement.current_revision
    @revision.eta = Date.today if @revision.eta.nil?
    @cargo_types = CargoType.authorized
  end

  # POST /disbursements
  def create
    @disbursement = Disbursement.new(params[:disbursement])
    @disbursement.user = current_user
    @disbursement.office = current_user.office || Office.find_by_name("Head Office")

    respond_to do |format|
      if @disbursement.save
        format.html { redirect_to edit_disbursement_url(@disbursement) }
      else
        format.html { render action: "new" }
      end
    end
  end


  # PUT /disbursements/1
  # PUT /disbursements/1.json
  def update
    @disbursement = Disbursement.find(params[:id])
    if @disbursement.current_revision.number == 0
      @revision = @disbursement.current_revision
      @revision.number = 1
    else
      @revision = @disbursement.next_revision
    end
    respond_to do |format|
      if save_revision
        format.html { redirect_to disbursements_url, notice: 'Disbursement was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /disbursements/1
  # DELETE /disbursements/1.json
  def destroy
    @disbursement = Disbursement.find(params[:id])
    @disbursement.delete

    respond_to do |format|
      format.html { redirect_to disbursements_url }
      format.json { head :no_content }
    end
  end

  def access_log
    @geoip = GeoIP.new(Rails.root.join('GeoLiteCity.dat').to_s)
    @disbursement = Disbursement.find(params[:id])
    add_breadcrumb "Access log for #{@disbursement.current_revision.reference}"
  end

  private
  def save_revision
    if not @revision.update_attributes(params[:disbursement_revision])
      return false
    end
    # handle extra items
    old_extras = @revision.field_keys.map {|k| k.starts_with?("EXTRAITEM") ? k : nil }.compact
    extras = params.keys.map {|k| k.starts_with?("value_EXTRAITEM") ? k.split('_')[1] : nil}.compact
    # remove keys that do not exist anymore
    old_extras.each do |k|
      if not extras.member? k
        @revision.fields.delete(k)
        @revision.codes.delete(k)
        @revision.descriptions.delete(k)
        @revision.values.delete(k)
        @revision.values_with_tax.delete(k)
      end
    end
    # reindex field_keys
    fields = {}
    @revision.field_keys.each_with_index do |k,i|
      fields[k] = i
    end
    # add new items
    next_val = fields.values.max+1 rescue 1
    ctx = V8::Context.new
    extras.each do |k|
      if not old_extras.member? k
        fields[k] = next_val
        @revision.compulsory[k] = "0"
        taxApplies = "true"
        begin
          taxApplies = ctx.eval("("+params["code_#{k}"]+").taxApplies") ? "true" : "false"
        rescue
        end
        @revision.codes[k] = "{compute: function(c) {return 0;},taxApplies: #{taxApplies}}"
        @revision.descriptions[k] = params["description_#{k}"]
        next_val += 1
      end
    end
    @revision.fields = fields
    fields.keys.each do |k|
      val = params["disabled_#{k}"]
      if val and not @revision.compulsory?(k)
        @revision.disabled[k] = (val == "1" ? "1" : "0")
      end
      val = params["overriden_#{k}"]
      if val and val != ""
        @revision.overriden[k] = val
      else
        @revision.overriden.delete(k)
      end
      @revision.comments[k] = params["comment_#{k}"]
    end
    @revision.compute
    @revision.user = current_user
    @revision.save
    @disbursement.current_revision = @revision
    @disbursement.save
  end

  def shortcuts
    @total = number_to_currency @revision.data['total'], unit: ""
    @total_with_tax = number_to_currency @revision.data['total_with_tax'],
                                         unit: ""
    @currency_code = @revision.data["currency_code"]
  end

  def format_pdf
    # default format is letter, that is 612x792 pdf points
    # there are 72 pdf points in one inch
    # the page has a 0.5 default margin setup
    # the resulting usable size is 540x720
    # the pdf coordinates origin is at the bottom left angle of the page
    @pdf = Prawn::Document.new :page_layout => :portrait

    shortcuts
    font_setup
    pdf_header
    to_table
    from_table
    services_table
    final_figure
    @pdf.move_down(72)
    @pdf.stroke_line [0,@pdf.y], [540,@pdf.y]
    bank_details_and_conditions


  end

  def font_setup
    # setup fallback fonts for asian charsets
    @pdf.font_size = 8
    @pdf.font_families.update(
      "DejaVuSans" => {
        :bold => Rails.root.join('fonts', 'DejaVuSans-Bold.ttf').to_s,
        :normal => Rails.root.join('fonts', 'DejaVuSans.ttf').to_s })
    kai = "#{Prawn::BASEDIR}/data/fonts/gkai00mp.ttf"
    @pdf.font_families.update(
      "Kai" => {
          :normal => { :file => kai, :font => "Kai" },
          :bold   => kai,
          :italic => kai,
          :bold_italic => kai})
    @pdf.font "DejaVuSans"
    @pdf.fallback_fonts = ["Kai"]
  end

  def pdf_title(title, subtitle)
      @pdf.text title,
                :size => 20, :style => :bold,
                :align => :left, :valign => :center
      if subtitle
        @pdf.text "\n#{subtitle}",
                :size => 10, :style => :bold,
                :alight => :left, :valign => :center
      end
  end

  def pdf_header
    # title and logo
    @pdf.fill_color = '000000'
    logo_path = Rails.root.join('app', 'assets', 'images',
                                ProformaDA::Application.config.tenant_da_logo)
    @pdf.bounding_box([0, 720], width: 540, height: 160) do
      if @disbursement.draft?
        pdf_title("DRAFT PROFORMA DISBURSEMENT", nil)
      elsif @disbursement.initial?
        pdf_title("PROFORMA DISBURSEMENT", "Sent prior to vessel arrival")
      elsif @disbursement.final?
        pdf_title("FINAL CLOSE ESTIMATE", "Sent after vessel sailing")
      end
      @pdf.image logo_path, :width => 60,
                            :position => :right,
                            :vposition => :center
    end
  end

  def to_table
    @pdf.bounding_box([0, 560], width: 270, height: 300) do
      @pdf.fill_color = '123123'
      data = [
        ['<b>To</b>', "<b>#{@revision.data['company_name']}</b>\n#{@revision.data['company_email']}"],
        ['<b>Reference</b>', @revision.reference],
        ['<b>Issued</b>', I18n.l(@revision.updated_at.to_date)],
        ['<b>Vessel<b>', "#{@disbursement.vessel_name}\n<font size=\"5\">(GRT: #{@revision.data["vessel_grt"]} | NRT: #{@revision.data["vessel_nrt"]} | DWT: #{@revision.data["vessel_dwt"]} | LOA: #{@revision.data["vessel_loa"]})</font>"]
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
      @pdf.table data,
                 cell_style: {border_widths: [0.1, 0, 0.1, 0],
                              inline_format: true,
                              border_color: 'dddddd'},
                 column_widths: [70, 200]
    end
  end

  def from_table
    @pdf.bounding_box([315, 560], width: 225, height: 300) do
      data = [
        ['<b>From</b>', "<b>#{@revision.data['office_name']||@revision.data['from_name']}</b>\n#{@revision.data['office_address1']||@revision.data['from_address1']}\n#{@revision.data['office_address2']||@revision.data['from_address2']}\n#{@revision.data['office_address3']}#{ "\n" unless @revision.data['office_address3'].blank? }#{@revision.email}"]
      ]
      @pdf.table data,
                 cell_style: {border_widths: [0.1, 0, 0.1, 0],
                              inline_format: true,
                              border_color: 'dddddd'},
                 column_widths: [70, 155]
    end
  end

  def services_table
    services_data = [
      # table header
      [
        {:content => "<b>Item</b>"},
        {content: "<b>Amount (#{@currency_code})</b>",
         align: :right},
        {content: "<b>Amount (#{@currency_code}) Including Taxes</b>",
         align: :right},
      ]
    ]
    # real service data
    @revision.field_keys.each do |f|
      next if @revision.disabled[f] == "1"
      desc = @revision.descriptions[f]
      if @revision.comments and @revision.comments[f] and @revision.comments[f] != ''
        desc += " <font size=\"5\">#{@revision.comments[f]}</font>"
      end
      services_data <<  [
        desc,
        {content: number_to_currency(nan_to_zero(@revision.values[f]), unit: ""),
         align: :right},
        {content: number_to_currency(nan_to_zero(@revision.values_with_tax[f]), unit: ""),
         align: :right}
      ]
    end
    # totals
    services_data << [
      '<b>Total</b>',
      {content: "<b>#{@total}<b>",
       align: :right},
      {content: "<b><font size=\"12\">#{@total_with_tax}</font></b>",
       align: :right}
    ]

    # Remove tax included column if needed
    column_widths = @revision.tax_exempt? ? [315, 225] : [180, 135, 225]
    if @revision.tax_exempt?
      services_data = services_data.map {|d| d.slice(0,2)}
    end

    # Draw the service table
    @pdf.y = 340
    table = @pdf.make_table(services_data,
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
    table = @pdf.make_table([data],
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
<b>Reference: #{@disbursement.vessel_name}</b>

Disclaimer: this is only an estimate and any additional costs incurred for this vessel will be accounted for in our Final D/A.

This estimate is exclusive of Australian Freight Tax (AFT) which, if applicable, shall be paid by the freight beneficiary, ie owner/disponent owner.

TXT
    @pdf.text txt, inline_format: true
    if @revision.tax_exempt?
      @pdf.text "This estimate is exclusive of Australian Goods and Services Tax (GST).  The GST portion will be claimed back from the Australian Tax Office on your behalf.\n\n", inline_format: true
    else
      @pdf.text "This estimate is inclusive of Australian Goods and Services Tax (GST).\n\n", inline_format: true
    end
    @pdf.text "Note: providers of towage services in Australia use their own amended versions of the UK Standard Conditions for Towage and other Services, copies of which are available upon request or from the towage provider’s website.\n\n", inline_format: true
    @pdf.text "Download the full <link href=\"#{root_url}#{ProformaDA::Application.config.tenant_terms}\">Terms and Conditions</link>", inline_format: true
  end

  def format_xls
    shortcuts
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    head_left = Spreadsheet::Format.new weight: :bold,
                                         horizontal_align: :left
    head_right = Spreadsheet::Format.new weight: :bold,
                                          horizontal_align: :right
    left = Spreadsheet::Format.new horizontal_align: :left
    right = Spreadsheet::Format.new horizontal_align: :right
    total = Spreadsheet::Format.new weight: :bold, size: 16,
                                    horizontal_align: :right
    title = Spreadsheet::Format.new weight: :bold, size: 16,
                                    color: :red,
                                    horizontal_align: :center
    subtitle = Spreadsheet::Format.new weight: :bold, size: 12,
                                       horizontal_align: :center
    sheet = book.create_worksheet
    sheet.name = "Proforma DA"
    (0..3).each {|i| sheet.column(i).width = 40}

    r = 0

    # draw title
    sheet.row(r).push ProformaDA::Application.config.tenant_full_name.upcase
    sheet.row(r).default_format = title
    sheet.row(r).height = 20
    sheet.merge_cells(r, 0, r, 3)
    r += 2

    # draw subtitle
    sheet.row(r).push "ESTIMATED DISBURSEMENTS FOR #{@disbursement.port.name.upcase}"
    sheet.row(r).default_format = subtitle
    sheet.row(r).height = 18
    sheet.merge_cells(r, 0, r, 3)
    r += 2

    # draw vessel info
    sheet.row(r).push "Vessel", @disbursement.vessel_name
    sheet.row(r).set_format(0, head_left)
    r += 1
    unless @revision.voyage_number.blank?
      sheet.row(r).push "Voyage Number", @revision.voyage_number
      sheet.row(r).set_format(0, head_left)
      r += 1
    end
    sheet.row(r).push "ETA", "#{I18n.l(@revision.eta) rescue "N/A"}"
    sheet.row(r).set_format(0, head_left)
    r += 1
    ["grt", "nrt", "dwt", "loa"].each do |n|
      sheet.row(r).push n.upcase, @revision.data["vessel_#{n}"]
      sheet.row(r).set_format(0, head_left)
      r += 1
    end

    r += 1

    # setup services
    sheet.row(r).push "Item",
                      "Comment",
                      "Amount (#{@currency_code})"
    sheet.row(r).push "Amount (#{@currency_code}) Including Taxes" unless @revision.tax_exempt?
    sheet.row(r).default_format = head_right
    (0..1).each {|i| sheet.row(r).set_format(i, head_left) }
    r += 1
    @revision.field_keys.each_with_index do |k, i|
      sheet.row(r+i).push @revision.descriptions[k],
                          @revision.comments[k],
                          nan_to_zero(@revision.values[k])
      unless @revision.tax_exempt?
        sheet.row(r+i).push nan_to_zero(@revision.values_with_tax[k])
      end
      sheet.row(r+i).default_format = right
      (0..1).each {|c| sheet.row(r+i).set_format(c, left) }
    end
    r += @revision.field_keys.length
    sheet.row(r).push "ESTIMATED AMOUNT",
                      "",
                      "#{number_to_currency @total, unit: ""}"
    unless @revision.tax_exempt?
      sheet.row(r).push "#{number_to_currency @total_with_tax, unit: ""}"
    end
    sheet.row(r).default_format = total
    sheet.row(r).height = 20
    sheet.merge_cells(r, 0, r, @revision.tax_exempt? ? 1 : 2)
    book
  end
end
