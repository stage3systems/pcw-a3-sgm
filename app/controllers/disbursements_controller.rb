# encoding: utf-8
class DisbursementsController < ApplicationController
  before_filter :authenticate_user!, :except => :published
  add_breadcrumb "Proforma Disbursements", :disbursements_url

  # GET /disbursements
  # GET /disbursements.json
  def index
    @title = "Disbursements"
    includes = []
    joins = [:port, :current_revision]
    ((params["grid"]["f"]["companies.name"] rescue false) ? joins : includes) << :company
    ((params["grid"]["f"]["vessels.name"] rescue false) ? joins : includes) << :vessel
    @disbursements_grid = initialize_grid(Disbursement.where(
          port_id: current_user.authorized_ports.pluck(:id)
        ),
        joins: joins,
        include: includes,
        order: 'disbursement_revisions.updated_at',
        order_direction: 'desc',
        custom_order: {
          'disbursements.current_revision_id' => 'current_revision.updated_at',
          'disbursements.port_id' => 'port.name',
          'disbursements.company_id' => 'company.name'
        },
        per_page: 10)
    @disbursements = []
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @disbursements }
    end
  end

  def search
    respond_to do |format|
      format.json {
        render json: DisbursementSearch.new(params).results
      }
    end
  end

  def published
    @title = "Proforma DA"
    @disbursement = Disbursement.find_by_publication_id(params[:id])
    setup_revision
    @document = DisbursementDocument.new(@disbursement, @revision)
    setup_view

    respond_to do |format|
      format.html {
        if @revision and current_user.nil?
          @pfda_view.save
          DisbursementRevision.increment_counter :anonymous_views, @revision.id
        end
        render layout: "published"
      }
      format.pdf {
        handle_pdf
      }
      format.xls {
        handle_xls
      }
    end
  end

  def print
    @disbursement = Disbursement.find(params[:id])
    @revision = @disbursement.current_revision
    @document = DisbursementDocument.new(@disbursement, @revision)
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    send_data PdfDA.new(@document, root_url).render, type: "application/pdf",
              filename: "#{@revision.reference}#{ " - DRAFT" if @disbursement.draft? }.pdf"
  end


  def status
    @disbursement = Disbursement.find(params[:id])
    if ["draft", "initial", "close", "archived"].member? params[:status]
      @disbursement.send("#{params[:status]}!")
      @disbursement.save
      @disbursement.current_revision.schedule_sync
    end

    respond_to do |format|
      format.html { redirect_to disbursements_path}
      format.json { render json: @disbursement }
    end
  end

  def revisions
    @disbursement = Disbursement.find(params[:id])
    @title = "Revision for #{@disbursement.current_revision.data['vessel_name']} in #{@disbursement.port.name}#{ "/"+@disbursement.terminal.name if @disbursement.terminal} on #{l(@disbursement.current_revision.eta)}"
    add_breadcrumb @title
    @revisions = @disbursement.disbursement_revisions
  end

  def nominations
    api = AosApi.new
    render json: api.search('nomination', params.merge({'limit' => 10})).body
  end

  def nomination_details
    aos_nom = AosNomination.from_aos_id(params[:nomination_id])
    render json: aos_nom.to_json
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
    @title = "New PDA"
    @disbursement = Disbursement.new
    @disbursement.fill_nomination_data(params[:nomination_id])
    @disbursement
    params[:company_name] = @disbursement.company.name if @disbursement.company
    params[:vessel_name] = @disbursement.vessel.name if @disbursement.vessel
    @disbursement.status_cd = params[:status_cd].to_i
    @disbursement.tbn = @disbursement.inquiry?

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @disbursement }
    end
  end


  # GET /disbursements/1/edit
  def edit
    @title = "Edit PDA"
    @disbursement = Disbursement.find(params[:id])
    @revision = @disbursement.current_revision
    @revision.eta = Date.today if @revision.eta.nil?
    @cargo_types = CargoType.authorized
  end

  # POST /disbursements
  def create
    @title = "New PDA"
    @disbursement = Disbursement.new(disbursement_params)
    @disbursement.user = current_user
    @disbursement.office = current_user.office || Office.find_by_name("Head Office")

    respond_to do |format|
      if @disbursement.save
        format.html { redirect_to edit_disbursement_url(@disbursement) }
      else
        @disbursement.errors['company_name'] = @disbursement.errors['company_id'][0]
        format.html { render action: "new" }
      end
    end
  end


  # PUT /disbursements/1
  # PUT /disbursements/1.json
  def update
    @title = "Edit PDA"
    @disbursement = Disbursement.find(params[:id])
    if @disbursement.current_revision.number == 0
      @revision = @disbursement.current_revision
      @revision.number = 1
    else
      @revision = @disbursement.next_revision
    end
    @revision.user = current_user
    save_revision
    respond_to do |format|
      format.html { redirect_to disbursements_url,
                    notice: 'Disbursement was successfully updated.' }
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
    @title = "Published PDA Access Log"
    @geoip = GeoIP.new(Rails.root.join('GeoLiteCity.dat').to_s)
    @disbursement = Disbursement.find(params[:id])
    add_breadcrumb "Access log for #{@disbursement.current_revision.reference}"
  end

  private
  def handle_extra_items
    # handle extra items
    @old_extras = @revision.field_keys.map {|k| k.starts_with?("EXTRAITEM") ? k : nil }.compact
    @extras = params.keys.map {|k| k.starts_with?("value_EXTRAITEM") ? k.split('_')[1] : nil}.compact
    # remove keys that do not exist anymore
    @old_extras.each do |k|
      if not @extras.member? k
        @revision.fields.delete(k)
        @revision.codes.delete(k)
        @revision.descriptions.delete(k)
        @revision.values.delete(k)
        @revision.values_with_tax.delete(k)
      end
    end
  end

  def reindex_field_keys
    @fields = {}
    @revision.field_keys.each_with_index do |k,i|
      @fields[k] = i
    end
  end

  def add_new_items
    next_val = @fields.values.max+1 rescue 1
    @ctx = V8::Context.new
    @extras.each do |k|
      if not @old_extras.member? k
        @fields[k] = next_val
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
  end

  def compute_and_save_revision
    @revision.compute
    DisbursementRevision.hstore_fields.each do |f|
      @revision.send("#{f}_will_change!")
    end
    @revision.save
    @disbursement.current_revision = @revision
    @disbursement.save
  end

  def process_fields
    @fields.keys.each do |k|
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
  end

  def save_revision
    @revision.assign_attributes(disbursement_revision_params)
    handle_extra_items
    reindex_field_keys
    add_new_items
    @revision.fields = @fields
    process_fields
    compute_and_save_revision
  end

  def disbursement_params
    params.require(:disbursement).permit(
      :company_id, :dwt, :grt, :loa, :nrt,
      :port_id, :status_cd, :tbn, :terminal_id,
      :vessel_id, :tbn_template, :type_cd,
      :appointment_id, :nomination_id, :nomination_reference
    )
  end

  def disbursement_revision_params
    params.require(:disbursement_revision).permit(
      :cargo_qty, :data, :days_alongside, :descriptions,
      :disbursement_id, :loadtime,
      :tax_exempt, :tugs_in, :tugs_out, :values, :values_with_tax,
      :cargo_type_id, :comments, :eta, :disabled,
      :overriden, :voyage_number, :amount
    )
  end

  def setup_revision
    @revision_number = params[:revision_number]
    if @revision_number
      @revision = @disbursement.disbursement_revisions
                    .where(number: @revision_number.to_i).first
    else
      @revision = @disbursement.current_revision rescue nil
    end
  end

  def setup_view
    @pfda_view = PfdaView.new
    @pfda_view.disbursement_revision_id = @revision.id rescue nil
    @pfda_view.ip = request.remote_ip
    @pfda_view.browser = browser.name
    @pfda_view.browser_version = browser.version
    @pfda_view.user_agent = request.env['HTTP_USER_AGENT']
    @pfda_view.pdf = false
  end

  def handle_pdf
    if @revision and current_user.nil?
      @pfda_view.pdf = true
      @pfda_view.save
      DisbursementRevision.increment_counter :pdf_views, @revision.id
    end
    Dir.mkdir Rails.root.join('pdfs') unless Dir.exists? Rails.root.join('pdfs')
    file = Rails.root.join 'pdfs', "#{@revision.reference}.pdf"
    unless File.exists? file
      PdfDA.new(@document, root_url).render_file file
    end
    send_file(file, :type => "application/pdf")
  end

  def handle_xls
    #@revision.increment! :xls_views if @revision and current_user.nil?
    Dir.mkdir Rails.root.join('sheets') unless Dir.exists? Rails.root.join('sheets')
    file = Rails.root.join 'sheets', "#{@revision.reference}.xls"
    unless File.exists? file
      XlsDA.new(@document).write file
    end
    send_file(file, :type => "application/ms-excel")
  end
end
