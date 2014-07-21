class ServicesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :ensure_admin

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
    @service.changelog = 'Initial service definition'
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
    changelog = params[:service].delete(:changelog)
    @service = Service.new(safe_params)
    @service.port = @port
    @service.terminal = @terminal
    @service.user = current_user
    port_breadcrumb
    if @terminal
      add_breadcrumb "New Service", new_port_terminal_service_url(@port, @terminal)
    else
      add_breadcrumb "New Service", new_port_service_url(@port)
    end

    respond_to do |format|
      if @service.save
        update = ServiceUpdate.new()
        update.service = @service
        update.user = current_user
        update.changelog = changelog
        update.document = @service.document
        update.old_code = ''
        update.new_code = @service.code
        update.save!
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
    old_code = @service.code
    changelog = params[:service].delete(:changelog)
    @service.user = current_user if @service.user.nil?

    respond_to do |format|
      if @service.update_attributes(safe_params)
        update = ServiceUpdate.new()
        update.service = @service
        update.user = current_user
        update.changelog = changelog
        update.document = @service.document
        update.old_code = old_code
        update.new_code = @service.code
        update.save!
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
    get_port_and_terminal
    @port = Port.find(params[:port_id])
    @service = Service.find(params[:id])
    @service.destroy

    respond_to do |format|
      format.html {
        if @terminal
          redirect_to port_terminal_services_path(@port, @terminal)
        else
          redirect_to port_services_path(@port)
        end
      }
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

  def safe_params
    params.require(:service).permit(:code, :item, :key, :port_id, :row_order,
                                    :terminal_id, :document, :compulsory)
  end
end
