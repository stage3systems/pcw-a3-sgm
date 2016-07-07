class PortsController < CommonController
  before_filter :authenticate_user!
  before_filter :ensure_admin


  add_breadcrumb "Ports", :ports_url

  def model
    Port
  end

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
    @instance = current_tenant.ports.find(params[:id])
    add_breadcrumb "#{@instance.name}", port_url(@instance)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @instance.to_json(:include => [:services, :tax, :currency]) }
    end
  end

  private
  def safe_params
    metadata_keys = params[:port].try(:fetch, :metadata, {}).keys
    params.require(:port).permit(:name, :tax_id, :currency_id, {metadata: metadata_keys})
  end
end
