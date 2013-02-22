class EstimatesController < ApplicationController
  # GET /estimates
  # GET /estimates.json
  def index
    @estimates = Estimate.where(:status_cd => [Estimate.published, Estimate.draft])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @estimates }
    end
  end

  def published
    @published = Estimate.find_by_publication_id(params[:id])
    @revision = @published.current_revision rescue nil
    respond_to do |format|
      format.html { render layout: 'published' }
    end
  end

  def publish
    @estimate = Estimate.find(params[:id])
    @estimate.publish

    respond_to do |format|
      format.html { redirect_to estimates_path }
      format.json { render json: @estimate }
    end
  end

  def unpublish
    @estimate = Estimate.find(params[:id])
    @estimate.unpublish

    respond_to do |format|
      format.html { redirect_to estimates_path}
      format.json { render json: @estimate }
    end
  end

  # GET /estimates/1
  # GET /estimates/1.json
  def show
    @estimate = Estimate.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @estimate }
    end
  end

  # GET /estimates/new
  # GET /estimates/new.json
  def new
    @estimate = Estimate.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @estimate }
    end
  end

  # GET /estimates/1/edit
  def edit
    @estimate = Estimate.find(params[:id])
    @revision = EstimateRevision.next_from_estimate(@estimate)
  end

  # POST /estimates
  def create
    @estimate = Estimate.new(params[:estimate])

    respond_to do |format|
      if @estimate.save
        format.html { redirect_to edit_estimate_url(@estimate) }
      else
        format.html { render action: "new" }
      end
    end
  end

  def crystalize_revision
    total = BigDecimal("0")
    total_with_tax = BigDecimal("0")
    @revision.field_keys.each do |k|
      value = params["value_#{k}"]
      @revision.values[k] = value
      total += BigDecimal(value)
      value_with_tax = params["value_with_tax_#{k}"]
      @revision.values_with_tax[k] = value_with_tax
      total_with_tax += BigDecimal(value_with_tax)
    end
    @revision.data["total"] = total.round(2).to_s
    @revision.data["total_with_tax"] = total_with_tax.round(2).to_s
    @revision.save
  end

  # PUT /estimates/1
  # PUT /estimates/1.json
  def update
    @estimate = Estimate.find(params[:id])
    @revision = @estimate.current_revision
    respond_to do |format|
      if @revision.update_attributes(params[:estimate_revision])
        crystalize_revision
        format.html { redirect_to estimates_url, notice: 'Estimate was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /estimates/1
  # DELETE /estimates/1.json
  def destroy
    @estimate = Estimate.find(params[:id])
    @estimate.delete

    respond_to do |format|
      format.html { redirect_to estimates_url }
      format.json { head :no_content }
    end
  end
end
