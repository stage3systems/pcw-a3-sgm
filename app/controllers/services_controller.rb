class ServicesController < ApplicationController
  def index
    get_port_and_terminal
    port_breadcrumb
    if @terminal
      @services = @terminal.services.all
    else
      @services = @port.services.all
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @services }
    end
  end

  def sort
    @service = Service.find(params[:id])
    @service.row_order_position = params[:row_order_position]
    @service.save
    render nothing: true
  end

  def show
    get_port_and_terminal
    @service = Service.find(params[:id])
    port_breadcrumb
    if @terminal
      add_breadcrumb @service.item, port_terminal_service_url(@port, @terminal, @service)
    else
      add_breadcrumb @service.item, port_service_url(@port, @service)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @service }
    end
  end

  def new
    get_port_and_terminal
    @service = Service.new
    @service.port = @port
    @service.terminal = @terminal
    @service.code = "{\n  compute: function(ctx) {\n    return 0;\n  },\n  taxApplies: false\n}\n"
    port_breadcrumb
    if @terminal
      add_breadcrumb "New Service", new_port_terminal_service_url(@port, @terminal)
    else
      add_breadcrumb "New Service", new_port_service_url(@port)
    end


    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @service }
    end
  end

  def edit
    get_port_and_terminal
    @service = Service.find(params[:id])
    port_breadcrumb
    if @terminal
      add_breadcrumb "Edit #{@service.item}", edit_port_terminal_service_url(@port, @terminal, @service)
    else
      add_breadcrumb "Edit #{@service.item}", edit_port_service_url(@port, @service)
    end
  end

  def create
    get_port_and_terminal
    @service = Service.new(params[:service])
    @service.port = @port
    @service.terminal = @terminal
    port_breadcrumb
    if @terminal
      add_breadcrumb "New Service", new_port_terminal_service_url(@port, @terminal)
    else
      add_breadcrumb "New Service", new_port_service_url(@port)
    end

    respond_to do |format|
      if @service.save
        format.html {
          if @terminal
            notice = 'Service was successfully created.'
            redirect_to port_terminal_services_path(@port, @terminal), notice: notice
          else
            redirect_to port_services_path(@port), notice: notice
          end
        }
        format.json { render json: @service, status: :created, location: @service }
      else
        format.html { render action: "new" }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    get_port_and_terminal
    @service = Service.find(params[:id])

    respond_to do |format|
      if @service.update_attributes(params[:service])
        format.html {
          notice = 'Service was successfully updated.'
          if @terminal
            redirect_to port_terminal_services_path(@port, @terminal), notice: notice
          else
            redirect_to port_services_path(@port), notice: notice
          end
        }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @service = Service.find(params[:id])
    @service.destroy

    respond_to do |format|
      format.html { redirect_to port_services_url(@port) }
      format.json { head :no_content }
    end
  end
  private

  def get_port_and_terminal
    @port = Port.find(params[:port_id])
    @terminal = Terminal.find_by_id(params[:terminal_id])
  end

  def port_breadcrumb
    add_breadcrumb "Ports", ports_url
    add_breadcrumb "#{@port.name}", port_url(@port)
    if @terminal
      add_breadcrumb "Terminals", port_terminals_url(@port)
      add_breadcrumb @terminal.name, port_terminal_url(@port, @terminal)
      add_breadcrumb "Services", port_terminal_services_url(@port, @terminal)
    else
      add_breadcrumb "Services", port_services_url(@port)
    end
  end
end
