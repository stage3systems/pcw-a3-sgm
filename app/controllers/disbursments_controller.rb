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
      format.html
      format.pdf {
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

  def format_pdf_assert_space(n)
    if @gridy+n >= @nrows
      @pdf.grid([@gridy,0],[@gridy+n-1,@ncols-1]).bounding_box do
        @pdf.cell :width => @pdf.bounds_width, :height => @pdf.bounds.height,
                  :border_width => 0
      end
      @gridy = 0
      @pdf.start_new_page
    end
  end

  def format_published_pdf
    @pdf = Prawn::Document.new :page_layout => :portrait
    @pdf.font_size = 6
    @pdf.font_families.update(
      "DejaVuSans" => { :bold => Rails.root.join('fonts', 'DejaVuSans-Bold.ttf').to_s,
                        :normal => Rails.root.join('fonts', 'DejaVuSans.ttf').to_s })
    @pdf.font "DejaVuSans"
    @nrows = 72
    @ncols = 12
    @pdf.define_grid :columns => @ncols, :rows => @nrows, :gutter => 0
    @gridy = 0
    @pdf.fill_color = '000000'
    format_pdf_assert_space 10
    logo_path = Rails.root.join('app', 'assets', 'images', 'monson_agency.png')
    @pdf.grid([0,0], [9, 5]).bounding_box do
      @pdf.text "PROFORMA DISBURSMENT", :size => 12, :style => :bold,
                :align => :left, :valign => :center
    end
    @pdf.grid([0, 6], [9, @ncols-1]).bounding_box do
      @pdf.image logo_path, :width => 40, :position => :right, :vposition => :center
    end
    @gridy += 10
    format_pdf_assert_space 18
    @pdf.grid([@gridy, 0], [@gridy+18, 5]).bounding_box do
      @pdf.fill_color = '123123'
      data = [
        ['<b>To</b>', "<b>#{@revision.data['company_name']}</b>\n#{@revision.data['company_email']}"],
        ['<b>Reference</b>', @revision.reference],
        ['<b>Issued</b>', I18n.l(@revision.updated_at.to_date)],
        ['<b>Vessel<b>', "#{@published.vessel_name} <font size=\"4.5\">(GRT: #{@revision.data["vessel_grt"]} | NRT: #{@revision.data["vessel_nrt"]} | DWT: #{@revision.data["vessel_dwt"]} | LOA: #{@revision.data["vessel_loa"]})</font>"],
        ['<b>Port</b>', @published.port.name],
        ['<b>Cargo Type</b>', (@revision.cargo_type.display rescue "N/A")],
        ['<b>Cargo Quantity</b>', @revision.cargo_qty],
        ['<b>Load Time (Hours)</b>', @revision.loadtime],
        ['<b>Tugs</b>', "#{@revision.tugs_in} In - #{@revision.tugs_out} Out"]
      ]
      @pdf.table data,
                 cell_style: {border_widths: [0.1, 0, 0, 0], inline_format: true},
                 column_widths: [70, 200]
    end
    @pdf.grid([@gridy, 7], [@gridy+18, @ncols-1]).bounding_box do
      data = [
        ['<b>From</b>', "<b>#{@revision.data['from_name']}</b>\n#{@revision.data['from_address1']}\n#{@revision.data['from_address2']}"]
      ]
      @pdf.table data,
                 cell_style: {border_widths: [0.1, 0, 0, 0], inline_format: true},
                 column_widths: [70, 155]
    end
    @gridy += 18
    format_pdf_assert_space 1
    column_widths = [180, 135, 225]
    if @revision.tax_exempt?
      column_widths = [315, 225]
    end
    @pdf.grid([@gridy, 0], [@gridy+1, @ncols-1]).bounding_box do
      data = [
        ['<b>Item</b>', "<b>Amount (#{@revision.data["currency_code"]})</b>", "<b>Amount (#{@revision.data["currency_code"]}) Including Taxes</b>"]
      ]
      if @revision.tax_exempt?
        data = data.map {|d| d.slice(0,2)}
      end
      @pdf.table data,
                 cell_style: {border_widths: [0, 0, 0, 0], height: 10,
                              padding: 1, inline_format: true},
                 column_widths: column_widths
    end
    @gridy += 1
    @revision.field_keys.each do |f|
      next if @revision.disabled[f]
      desc = @revision.descriptions[f]
      height = 10
      space = 1
      if @revision.comments and @revision.comments[f] and @revision.comments[f] != ''
        desc += " <font size=\"4.5\">#{@revision.comments[f]}</font>"
      end
      format_pdf_assert_space space
      @pdf.grid([@gridy, 0], [@gridy+1, @ncols-1]).bounding_box do
        data = [
          [desc, number_to_currency(@revision.values[f]), number_to_currency(@revision.values_with_tax[f])]
        ]
        if @revision.tax_exempt?
          data = data.map {|d| d.slice(0,2)}
        end
        @pdf.table data,
                   cell_style: {border_widths: [0.1, 0, 0, 0], height: height,
                                padding: 1, inline_format: true},
                   column_widths: column_widths
      end
      @gridy += space
    end
    format_pdf_assert_space 2
    @pdf.grid([@gridy, 0], [@gridy+2, @ncols-1]).bounding_box do
      if @revision.tax_exempt?
        data = [
          ['<b>Total</b>', "<b><font size=\"16\">#{number_to_currency(@revision.data['total'])}</font></b>"]
        ]
      else
        data = [
          ['<b>Total</b>', "<b>#{number_to_currency(@revision.data["total"])}<b>",
                           "<b><font size=\"14\">#{number_to_currency(@revision.data['total_with_tax'])}</font></b>"]
        ]
      end
      @pdf.table data, 
                 cell_style: {border_widths: [0.1, 0, 0, 0], height: 20,
                              padding: 1, inline_format: true},
                 column_widths: column_widths
    end
    @gridy += 2
    @pdf.move_down(20)
    @pdf.table [['']],
               cell_style: {border_widths: [0.1, 0, 0, 0]},
               column_widths: [540]
    @pdf.text "Please remit funds at least two (2) days prior to vessels arrival to the following Bank Account:\n\n<b>#{@revision.data['bank_name']}</b>\n<b>#{@revision.data['bank_address1']}</b>\n<b>#{@revision.data['bank_address2']}</b>\n\n<b>SWIFT Code: #{@revision.data['swift_code']}</b>\n<b>BSB Number: #{@revision.data['bsb_number']}</b>\n<b>A/C Number: #{@revision.data['ac_number']}</b>\n<b>A/C Name: #{@revision.data['ac_name']}</b>\n<b>Reference: #{@published.vessel_name}</b>\n\nDisclaimer: this is only an estimate and any additional costs incurred for this vessel will be accounted for in our Final D/A.\n\nThis estimate is exclusive of Australian Freight Tax (AFT) which, if applicable, shall be paid by the freight beneficiary, ie owner/disponent owner.\n\n", inline_format: true
    if @revision.tax_exempt?
      @pdf.text "This estimate is exclusive of Australian Goods and Services Tax (GST).  The GST portion will be claimed back from the Australian Tax Office on your behalf.\n\n", inline_format: true
    else
      @pdf.text "This estimate is inclusive of Australian Goods and Services Tax (GST).\n\n", inline_format: true
    end
    @pdf.text "Download the full <link href=\"https://monson-disbursments.evax.fr/MAA%20Standard%20Terms%20and%20Conditions%20Sep%202012.pdf\">Terms and Conditions</link>", inline_format: true
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

    respond_to do |format|
      if @disbursment.save
        format.html { redirect_to edit_disbursment_url(@disbursment) }
      else
        format.html { render action: "new" }
      end
    end
  end

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
    @revision.save
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
end
