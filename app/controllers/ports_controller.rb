class PortsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :ensure_admin

  add_breadcrumb "Ports", :ports_url

  # GET /ports
  # GET /ports.json
  def index
    @title = "Ports"
    @ports_grid = initialize_grid(
                    current_user.authorized_ports,
                    joins: [:tax, :currency],
                    order: 'ports.name',
                    order_direction: 'asc')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /ports/1
  # GET /ports/1.json
  def show
    @title = "View Port"
    @port = Port.find(params[:id])
    add_breadcrumb "#{@port.name}", port_url(@port)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @port.to_json(:include => [:services, :tax, :currency]) }
    end
  end

  # GET /ports/new
  # GET /ports/new.json
  def new
    @title = "New Port"
    @port = Port.new
    add_breadcrumb "New Port", new_port_url

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @port }
    end
  end

  # GET /ports/1/edit
  def edit
    @title = "Edit Port"
    @port = Port.find(params[:id])
    add_breadcrumb "Edit #{@port.name}", edit_port_url(@port)
  end

  # POST /ports
  # POST /ports.json
  def create
    @title = "New Port"
    @port = Port.new(params[:port])
    add_breadcrumb "New Port", new_port_url

    respond_to do |format|
      if @port.save
        format.html { redirect_to @port, notice: 'Port was successfully created.' }
        format.json { render json: @port, status: :created, location: @port }
      else
        format.html { render action: "new" }
        format.json { render json: @port.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ports/1
  # PUT /ports/1.json
  def update
    @title = "Edit Port"
    @port = Port.find(params[:id])
    add_breadcrumb "Edit #{@port.name}", edit_port_url(@port)

    respond_to do |format|
      if @port.update_attributes(params[:port])
        format.html { redirect_to @port, notice: 'Port was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @port.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ports/1
  # DELETE /ports/1.json
  def destroy
    @port = Port.find(params[:id])
    @port.destroy

    respond_to do |format|
      format.html { redirect_to ports_url }
      format.json { head :no_content }
    end
  end
end
