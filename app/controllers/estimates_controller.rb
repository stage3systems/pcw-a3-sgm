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
    @fields = @published.fields.sort_by {|k, v| v.to_i }.map {|k,i| k }
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
  end

  # POST /estimates
  # POST /estimates.json
  def create
    @estimate = Estimate.new(params[:estimate])
    crystalize_estimate
    respond_to do |format|
      if @estimate.save
        format.html { redirect_to @estimate, notice: 'Estimate was successfully created.' }
        format.json { render json: @estimate, status: :created, location: @estimate }
      else
        format.html { render action: "new" }
        format.json { render json: @estimate.errors, status: :unprocessable_entity }
      end
    end
  end

  def crystalize_estimate
    port = Port.find(params[:estimate][:port_id]) rescue nil
    return if port.nil?
    total = BigDecimal("0")
    total_with_tax = BigDecimal("0")
    ["fields", "descriptions", "values", "values_with_tax", "data"].each do |k|
      @estimate.send("#{k}=", {}) if @estimate.send(k).nil?
    end
    port.charges.each_with_index do |c, i|
      @estimate.fields[c.key] = i
      @estimate.descriptions[c.key] = c.name
      value = params["value_#{c.key}"]
      @estimate.values[c.key] = value 
      total += BigDecimal(value)
      value_with_tax = params["value_with_tax_#{c.key}"]
      @estimate.values_with_tax[c.key] = value_with_tax
      total_with_tax += BigDecimal(value_with_tax)
    end
    @estimate.data["total"] = total.round(2).to_s
    @estimate.data["total_with_tax"] = total_with_tax.round(2).to_s
  end

  # PUT /estimates/1
  # PUT /estimates/1.json
  def update
    @estimate = Estimate.find(params[:id])
    crystalize_estimate

    puts params
    respond_to do |format|
      if @estimate.update_attributes(params[:estimate])
        format.html { redirect_to @estimate, notice: 'Estimate was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @estimate.errors, status: :unprocessable_entity }
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
