class DisbursmentsController < ApplicationController
  before_filter :authenticate_user!, :except => :published
  add_breadcrumb "Proforma Disbursments", :disbursments_url
  include ActionView::Helpers::NumberHelper

  # GET /disbursments
  # GET /disbursments.json
  def index
    @disbursments = Disbursment.where(:status_cd => [Disbursment.published, Disbursment.draft])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @disbursments }
    end
  end

  def published
    @published = Disbursment.find_by_publication_id(params[:id])
    @revision = @published.current_revision rescue nil
    respond_to do |format|
      format.html {
        @revision.increment! :anonymous_views if @revision and current_user.nil?
      }
      format.pdf {
        @revision.increment! :pdf_views if @revision and current_user.nil?
        Dir.mkdir Rails.root.join('pdfs') unless Dir.exists? Rails.root.join('pdfs')
        file = Rails.root.join 'pdfs', "#{@revision.reference}.pdf"
        unless  File.exists? file
          format_published_pdf
          @pdf.render_file file
        end
        send_file(file, :type => "application/pdf")
      }
    end
  end

  def publish
    @disbursment = Disbursment.find(params[:id])
    @disbursment.publish

    respond_to do |format|
      format.html { redirect_to disbursments_path }
      format.json { render json: @disbursment }
    end
  end

  def unpublish
    @disbursment = Disbursment.find(params[:id])
    @disbursment.unpublish

    respond_to do |format|
      format.html { redirect_to disbursments_path}
      format.json { render json: @disbursment }
    end
  end

  # GET /disbursments/1
  # GET /disbursments/1.json
  def show
    @disbursment = Disbursment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @disbursment }
    end
  end

  # GET /disbursments/new
  # GET /disbursments/new.json
  def new
    @disbursment = Disbursment.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @disbursment }
    end
  end

  # GET /disbursments/1/edit
  def edit
    @disbursment = Disbursment.find(params[:id])
    @revision = @disbursment.current_revision
    @cargo_types = CargoType.all
  end

  # POST /disbursments
  def create
    @disbursment = Disbursment.new(params[:disbursment])
    @disbursment.user = current_user

    respond_to do |format|
      if @disbursment.save
        format.html { redirect_to edit_disbursment_url(@disbursment) }
      else
        format.html { render action: "new" }
      end
    end
  end


  # PUT /disbursments/1
  # PUT /disbursments/1.json
  def update
    @disbursment = Disbursment.find(params[:id])
    if @disbursment.current_revision.number == 0
      @revision = @disbursment.current_revision
      @revision.number = 1
    else
      @revision = @disbursment.next_revision
    end
    respond_to do |format|
      if save_revision
        format.html { redirect_to disbursments_url, notice: 'Disbursment was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /disbursments/1
  # DELETE /disbursments/1.json
  def destroy
    @disbursment = Disbursment.find(params[:id])
    @disbursment.delete

    respond_to do |format|
      format.html { redirect_to disbursments_url }
      format.json { head :no_content }
    end
  end

  private
  def save_revision
    if not @revision.update_attributes(params[:disbursment_revision])
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
    next_val = fields.values.max+1
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
  end


  def format_published_pdf
    # default format is letter, that is 612x792 pdf points
    # there are 72 pdf points in one inch
    # the page has a 0.5 default margin setup
    # the resulting usable size is 540x720
    # the pdf coordinates origin is at the bottom right angle of the page
    @pdf = Prawn::Document.new :page_layout => :portrait

    font_setup
    pdf_header
    to_table
    from_table
    services_table
    @pdf.move_down(72)
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

  def pdf_header
    # title and logo
    @pdf.fill_color = '000000'
    logo_path = Rails.root.join('app', 'assets', 'images', 'monson_agency.png')
    @pdf.bounding_box([0, 720], width: 540, height: 100) do
      @pdf.text "PROFORMA DISBURSMENT", :size => 20, :style => :bold,
                :align => :left, :valign => :center
      @pdf.image logo_path, :width => 40,
                            :position => :right,
                            :vposition => :center
    end
  end

  def to_table
    @pdf.bounding_box([0, 620], width: 270, height: 300) do
      @pdf.fill_color = '123123'
      data = [
        ['<b>To</b>', "<b>#{@revision.data['company_name']}</b>\n#{@revision.data['company_email']}"],
        ['<b>Reference</b>', @revision.reference],
        ['<b>Issued</b>', I18n.l(@revision.updated_at.to_date)],
        ['<b>Vessel<b>', "#{@published.vessel_name}\n<font size=\"5\">(GRT: #{@revision.data["vessel_grt"]} | NRT: #{@revision.data["vessel_nrt"]} | DWT: #{@revision.data["vessel_dwt"]} | LOA: #{@revision.data["vessel_loa"]})</font>"],
        ['<b>Port</b>', @published.port.name],
        ['<b>Cargo Type</b>', (@revision.cargo_type.display rescue "N/A")],
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
    @pdf.bounding_box([315, 620], width: 225, height: 300) do
      data = [
        ['<b>From</b>', "<b>#{@revision.data['from_name']}</b>\n#{@revision.data['from_address1']}\n#{@revision.data['from_address2']}"]
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
        {content: "<b>Amount (#{@revision.data["currency_code"]})</b>",
         align: :right},
        {content: "<b>Amount (#{@revision.data["currency_code"]}) Including Taxes</b>",
         align: :right},
      ]
    ]
    # real service data
    @revision.field_keys.each do |f|
      next if @revision.disabled[f]
      desc = @revision.descriptions[f]
      if @revision.comments and @revision.comments[f] and @revision.comments[f] != ''
        desc += " <font size=\"5\">#{@revision.comments[f]}</font>"
      end
      services_data <<  [
        desc,
        {content: number_to_currency(@revision.values[f], unit: ""),
         align: :right},
        {content: number_to_currency(@revision.values_with_tax[f], unit: ""),
         align: :right}
      ]
    end
    # totals
    services_data << [
      '<b>Total</b>',
      {content: "<b>#{number_to_currency(@revision.data["total"])}<b>",
       align: :right},
      {content: "<b><font size=\"12\">#{number_to_currency(@revision.data['total_with_tax'])}</font></b>",
       align: :right}
    ]

    # Remove tax included column if needed
    column_widths = @revision.tax_exempt? ? [315, 225] : [180, 135, 225]
    if @revision.tax_exempt?
      services_data = services_data.map {|d| d.slice(0,2)}
    end

    # Draw the service table
    @pdf.y = 400
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

  def bank_details_and_conditions
    @pdf.text "Please remit funds at least two (2) days prior to vessels arrival to the following Bank Account:\n\n<b>#{@revision.data['bank_name']}</b>\n<b>#{@revision.data['bank_address1']}</b>\n<b>#{@revision.data['bank_address2']}</b>\n\n<b>SWIFT Code: #{@revision.data['swift_code']}</b>\n<b>BSB Number: #{@revision.data['bsb_number']}</b>\n<b>A/C Number: #{@revision.data['ac_number']}</b>\n<b>A/C Name: #{@revision.data['ac_name']}</b>\n<b>Reference: #{@published.vessel_name}</b>\n\nDisclaimer: this is only an estimate and any additional costs incurred for this vessel will be accounted for in our Final D/A.\n\nThis estimate is exclusive of Australian Freight Tax (AFT) which, if applicable, shall be paid by the freight beneficiary, ie owner/disponent owner.\n\n", inline_format: true
    if @revision.tax_exempt?
      @pdf.text "This estimate is exclusive of Australian Goods and Services Tax (GST).  The GST portion will be claimed back from the Australian Tax Office on your behalf.\n\n", inline_format: true
    else
      @pdf.text "This estimate is inclusive of Australian Goods and Services Tax (GST).\n\n", inline_format: true
    end
    @pdf.text "Download the full <link href=\"https://monson-disbursments.evax.fr/MAA%20Standard%20Terms%20and%20Conditions%20Sep%202012.pdf\">Terms and Conditions</link>", inline_format: true
  end
end
