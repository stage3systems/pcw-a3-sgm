# encoding: utf-8
class DisbursementsController < ApplicationController
  before_filter :authenticate_user!, :except => :published
  add_breadcrumb "Proforma Disbursements", :disbursements_url

  # GET /disbursements
  # GET /disbursements.json
  def index
    @title = "Disbursements"
    grid = DisbursementsGrid.new(current_user, params)
    @disbursements_grid = initialize_grid(grid.relation, grid.options)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def search
    respond_to do |format|
      format.json {
        render json: DisbursementSearch.new(current_tenant, params).results
      }
    end
  end

  def published
    @title = "Proforma DA"
    @disbursement = Disbursement.find_by(tenant_id: current_tenant.id,
                                         publication_id: params[:id])
    setup_revision
    @document = DisbursementDocument.new(@disbursement, @revision)
    setup_view

    respond_to do |format|
      format.html { @pfda_view.anonymous!; render layout: "published" }
      format.pdf { @pfda_view.pdf!; handle_pdf }
      format.xls { handle_xls }
    end
  end

  def print
    @disbursement = disbursement_by_id(params[:id])
    @revision = @disbursement.current_revision
    @document = DisbursementDocument.new(@disbursement, @revision)
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    send_data PdfDA.new(@document, root_url).render, type: "application/pdf",
              filename: "#{@revision.reference}#{ " - DRAFT" if @disbursement.draft? }.pdf"
  end


  def status
    @disbursement = disbursement_by_id(params[:id])
    set_disbursement_status(params[:status])

    respond_to do |format|
      format.html { redirect_to disbursements_path}
      format.json { render json: @disbursement }
    end
  end

  def revisions
    @disbursement = disbursement_by_id(params[:id])
    @title = "Revision for #{@disbursement.full_title}"
    add_breadcrumb @title
    @revisions = @disbursement.disbursement_revisions
  end

  # GET /disbursements/1
  # GET /disbursements/1.json
  def show
    @disbursement = disbursement_by_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @disbursement }
    end
  end

  # GET /disbursements/new
  # GET /disbursements/new.json
  def new
    @title = "New PDA"
    @disbursement = Disbursement.new(tenant_id: current_tenant.id)
    prefill_disbursement

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @disbursement }
    end
  end


  # GET /disbursements/1/edit
  def edit
    @title = "Edit PDA"
    @disbursement = disbursement_by_id(params[:id])
    @revision = @disbursement.current_revision
    @revision.eta = Date.today if @revision.eta.nil?
    @cargo_types = CargoType.authorized(current_tenant)
  end

  # POST /disbursements
  def create
    @title = "New PDA"
    @disbursement = Disbursement.new(disbursement_params.merge(tenant_id: current_tenant.id))
    set_user_and_office

    respond_to do |format|
      if @disbursement.save
        format.html { redirect_to edit_disbursement_url(@disbursement) }
      else

        if @disbursement.errors['nomination_id'][0]
          @err = [
              @disbursement.errors['nomination_id'][0],
              edit_disbursement_url(Disbursement.find_by(nomination_id: @disbursement.nomination_id))
          ]
        end

        @disbursement.errors['vessel_name'] = @disbursement.errors['vessel_id'][0]
        @disbursement.errors['company_name'] = @disbursement.errors['company_id'][0]
        format.html { render action: "new" }
      end
    end
  end


  # PUT /disbursements/1
  # PUT /disbursements/1.json
  def update
    @title = "Edit PDA"
    updater = DisbursementUpdater.new(params[:id], current_user)
    updater.run(disbursement_revision_params, params)

    respond_to do |format|
      format.html {
        d = updater.disbursement
        target = if d.draft?
            disbursements_url
        else
          published_short_url(d.publication_id)
        end
        redirect_to target,
                  notice: 'Disbursement was successfully updated.'
      }
    end
  end

  # DELETE /disbursements/1
  # DELETE /disbursements/1.json
  def destroy
    @disbursement = disbursement_by_id(params[:id])
    @disbursement.delete

    respond_to do |format|
      format.html { redirect_to disbursements_url }
      format.json { head :no_content }
    end
  end

  def access_log
    @title = "Published PDA Access Log"
    @geoip = GeoIP.new(Rails.root.join('GeoLiteCity.dat').to_s)
    @disbursement = disbursement_by_id(params[:id])
    add_breadcrumb "Access log for #{@disbursement.current_revision.reference}"
  end

  private
  def disbursement_params
    params.require(:disbursement).permit(
      :company_id, :dwt, :grt, :loa, :nrt, :sbt_certified,
      :port_id, :status_cd, :tbn, :terminal_id,
      :vessel_id, :tbn_template, :type_cd, :vessel_type, :vessel_subtype,
      :appointment_id, :nomination_id, :nomination_reference
    )
  end

  def disbursement_revision_params
    params.require(:disbursement_revision).permit(
      :cargo_qty, :data, :days_alongside, :descriptions,
      :disbursement_id, :loadtime, :supplier_name, :supplier_id,
      :tax_exempt, :tugs_in, :tugs_out, :values, :values_with_tax,
      :cargo_type_id, :comments, :eta, :disabled,
      :overriden, :voyage_number, :amount,
      :target_currency, :target_currency_rate
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
    @pfda_view.setup(current_tenant, request, browser, @revision)
  end

  def handle_pdf
    Dir.mkdir Rails.root.join('pdfs') unless Dir.exists? Rails.root.join('pdfs')
    file = Rails.root.join 'pdfs', "#{@revision.reference}.pdf"
    # unless File.exists? file
    # end
    PdfDA.new(@document, root_url).render_file file # always geenerate new pdf!
    send_file(file, :type => "application/pdf", :disposition => params[:inline].present? ? 'inline' : 'attachment')
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

  def set_disbursement_status(status)
    if ["draft", "initial", "close", "archived"].member? status
      @disbursement.send("#{status}!")
      @disbursement.save
      @disbursement.current_revision.update_status!
    end
  end

  def set_user_and_office
    @disbursement.user = current_user
    @disbursement.office = current_user.office || Office.find_by(name: "Head Office", tenant_id: current_tenant.id)
  end

  def prefill_disbursement
    @disbursement.fill_nomination_data(params[:nomination_id])
    params[:company_name] = @disbursement.company.name if @disbursement.company
    params[:vessel_name] = @disbursement.vessel.name if @disbursement.vessel
    @disbursement.status_cd = params[:status_cd].to_i
    @disbursement.tbn = @disbursement.inquiry?
  end

  def disbursement_by_id(id)
    Disbursement.where(tenant_id: current_tenant.id).find(id)
  end
end
