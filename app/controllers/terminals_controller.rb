class TerminalsController < BaseController
  before_filter :authenticate_user!
  before_filter :ensure_admin, :except => [:index]

  # GET /terminals
  # GET /terminals.json
  def index
    @port = Port.find(params[:port_id])
    @terminals = @port.terminals
    port_breadcrumb
    add_breadcrumb "Terminals", port_terminals_url(@port)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @terminals }
    end
  end

  # GET /terminals/1
  # GET /terminals/1.json
  def show
    @port = Port.find(params[:port_id])
    @terminal = Terminal.find(params[:id])
    port_breadcrumb
    add_breadcrumb "Terminals", port_terminals_url(@port)
    add_breadcrumb "#{@terminal.name}", port_terminal_url(@port, @terminal)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @terminal }
    end
  end

  # GET /terminals/new
  # GET /terminals/new.json
  def new
    @port = Port.find(params[:port_id])
    @terminal = Terminal.new
    port_breadcrumb
    add_breadcrumb "New Terminal", new_port_terminal_url(@port)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @terminal }
    end
  end

  # GET /terminals/1/edit
  def edit
    @port = Port.find(params[:port_id])
    @terminal = Terminal.find(params[:id])
    port_breadcrumb
    add_breadcrumb "Edit #{@terminal.name}", edit_port_terminal_url(@port, @terminal)
  end

  # POST /terminals
  # POST /terminals.json
  def create
    @port = Port.find(params[:port_id])
    @terminal = Terminal.new(safe_params)
    @terminal.port_id = @port.id
    port_breadcrumb
    add_breadcrumb "New Terminal", new_port_terminal_url(@port)

    @instance = @terminal
    form_response(@instance.save, [@port, @instance], "created", "new")
  end

  # PUT /terminals/1
  # PUT /terminals/1.json
  def update
    @port = Port.find(params[:port_id])
    @terminal = Terminal.find(params[:id])
    port_breadcrumb
    add_breadcrumb "Edit #{@terminal.name}", edit_port_terminal_url(@port, @terminal)

    @instance = @terminal
    form_response(@instance.update_attributes(safe_params),
                  [@port, @instance], "updated", "edit")
  end

  # DELETE /terminals/1
  # DELETE /terminals/1.json
  def destroy
    @port = Port.find(params[:port_id])
    @terminal = Terminal.find(params[:id])
    @terminal.destroy

    respond_to do |format|
      format.html { redirect_to port_terminals_url(@port) }
      format.json { head :no_content }
    end
  end

  private
  def port_breadcrumb
    add_breadcrumb "Ports", ports_url
    add_breadcrumb "#{@port.name}", port_url(@port)
  end

  def safe_params
    metadata_keys = params[:terminal].try(:fetch, :metadata, {}).keys
    params.require(:terminal).permit(:name, {metadata: metadata_keys})
  end

  def model
    Terminal
  end
end
