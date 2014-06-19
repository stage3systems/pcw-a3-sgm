class VesselsController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Vessels", :vessels_url

  # GET /vessels
  # GET /vessels.json
  def index
    @title = "Vessels"
    @vessels_grid = initialize_grid(Vessel,
                      order: 'vessels.name',
                      order_direction: 'asc')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /vessels/1
  # GET /vessels/1.json
  def show
    @title = "View Vessel"
    @vessel = Vessel.find(params[:id])
    add_breadcrumb "#{@vessel.name}", vessel_url(@vessel)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @vessel }
    end
  end

  # GET /vessels/new
  # GET /vessels/new.json
  def new
    @title = "New Vessel"
    @vessel = Vessel.new
    add_breadcrumb "New Vessel", new_vessel_url

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @vessel }
    end
  end

  # GET /vessels/1/edit
  def edit
    @title = "Edit Vessel"
    @vessel = Vessel.find(params[:id])
    add_breadcrumb "Edit #{@vessel.name}", edit_vessel_url(@vessel)
  end

  # POST /vessels
  # POST /vessels.json
  def create
    @title = "New Vessel"
    @vessel = Vessel.new(params[:vessel])
    add_breadcrumb "New Vessel", new_vessel_url

    respond_to do |format|
      if @vessel.save
        format.html { redirect_to @vessel, notice: 'Vessel was successfully created.' }
        format.json { render json: @vessel, status: :created, location: @vessel }
      else
        format.html { render action: "new" }
        format.json { render json: @vessel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /vessels/1
  # PUT /vessels/1.json
  def update
    @title = "Edit Vessel"
    @vessel = Vessel.find(params[:id])
    add_breadcrumb "Edit #{@vessel.name}", edit_vessel_url(@vessel)

    respond_to do |format|
      if @vessel.update_attributes(params[:vessel])
        format.html { redirect_to @vessel, notice: 'Vessel was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @vessel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vessels/1
  # DELETE /vessels/1.json
  def destroy
    @vessel = Vessel.find(params[:id])
    @vessel.destroy

    respond_to do |format|
      format.html { redirect_to vessels_url }
      format.json { head :no_content }
    end
  end
end
