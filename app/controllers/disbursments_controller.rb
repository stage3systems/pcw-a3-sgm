class DisbursmentsController < ApplicationController
  add_breadcrumb "Proforma Disbursments", :disbursments_url

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
      format.html { render layout: 'published' }
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
    @revision = DisbursmentRevision.next_from_disbursment(@disbursment)
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

  def crystalize_revision
    total = BigDecimal.new("0")
    total_with_tax = BigDecimal.new("0")
    @revision.field_keys.each do |k|
      value = params["value_#{k}"]
      @revision.values[k] = value
      total += BigDecimal.new(value)
      value_with_tax = params["value_with_tax_#{k}"]
      @revision.values_with_tax[k] = value_with_tax
      total_with_tax += BigDecimal.new(value_with_tax)
    end
    @revision.data["total"] = total.round(2).to_s
    @revision.data["total_with_tax"] = total_with_tax.round(2).to_s
    @revision.save
  end

  # PUT /disbursments/1
  # PUT /disbursments/1.json
  def update
    @disbursment = Disbursment.find(params[:id])
    @revision = @disbursment.current_revision
    respond_to do |format|
      if @revision.update_attributes(params[:disbursment_revision])
        crystalize_revision
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
