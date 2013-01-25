class ChargesController < ApplicationController
  def index
    @port = Port.find(params[:port_id])
    @charges = @port.charges.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ports }
    end
  end

  def sort
    @charge = Charge.find(params[:id])
    @charge.row_order_position = params[:row_order_position]
    @charge.save
    render nothing: true
  end

  def show
    @port = Port.find(params[:port_id])
    @charge = Charge.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @port }
    end
  end

  def new
    @port = Port.find(params[:port_id])
    @charge = Charge.new
    @charge.port = @port
    @charge.code = "{\n  compute: function(ctx) {\n    return 0;\n  },\n  taxApplies: false\n}\n"

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @port }
    end
  end

  def edit
    @port = Port.find(params[:port_id])
    @charge = Charge.find(params[:id])
  end

  def create
    puts params
    @port = Port.find(params[:port_id])
    @charge = Charge.new(params[:charge])
    @charge.port = @port

    respond_to do |format|
      if @charge.save
        format.html { redirect_to port_charges_path(@port), notice: 'Charge was successfully created.' }
        format.json { render json: @charge, status: :created, location: @charge }
      else
        format.html { render action: "new" }
        format.json { render json: @charge.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @port = Port.find(params[:port_id])
    @charge = Charge.find(params[:id])

    respond_to do |format|
      if @charge.update_attributes(params[:charge])
        format.html { redirect_to port_charges_path(@port), notice: 'Charge was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @charge.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @port = Port.find(params[:port_id])
    @charge = Charge.find(params[:id])
    @charge.destroy

    respond_to do |format|
      format.html { redirect_to port_charges_url(@port) }
      format.json { head :no_content }
    end
  end
end
