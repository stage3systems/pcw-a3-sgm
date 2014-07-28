class NestedCommonController < BaseController
  before_filter :authenticate_user!
  before_filter :ensure_admin

  def index
    get_port_and_terminal
    port_breadcrumb
    @instances = parent.send(association_name).all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @instances }
    end
  end

  def show
    get_port_and_terminal
    @instance = model.find(params[:id])
    port_breadcrumb
    add_breadcrumb @instance.name, show_url

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @instance }
    end
  end

  def new
    get_port_and_terminal
    @instance = model.new
    @instance = new_instance

    port_breadcrumb
    add_breadcrumb "New #{model_name}", new_url

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @instance }
    end
  end

  def edit
    get_port_and_terminal
    @instance = model.find(params[:id])
    port_breadcrumb
    add_breadcrumb "Edit #{@instance.name}", edit_url
  end

  def create
    get_port_and_terminal
    parse_params

    @instance = model.new(safe_params)
    populate_instance
    port_breadcrumb
    add_breadcrumb "New #{model_name}", new_url

    form_response(@instance.save, parent_url, "created", "new")
  end

  def update
    get_port_and_terminal
    @instance = model.find(params[:id])
    parse_params
    @instance.user = current_user if @instance.user.nil?

    form_response(@instance.update_attributes(safe_params),
                  parent_url, "updated", "edit")
  end

  def destroy
    get_port_and_terminal
    @instance = model.find(params[:id])
    @instance.destroy

    respond_to do |format|
      format.html {
        redirect_to parent_url
      }
      format.json { head :no_content }
    end
  end

  private
  def parent
    @parent ||= (@terminal || @port)
  end

  def parse_params
  end

  def new_instance
    @instance = model.new
  end

  def populate_instance
    @instance.port = @port
    @instance.terminal = @terminal
    @instance.user = current_user
  end

  def url_prefix
    @url_prefix ||= "port#{ "_terminal" if @terminal }"
  end

  def parent_url
    self.send("#{url_prefix}_#{association_name}_url",
              @port, @terminal)
  end

  def url_args
    [@port, @terminal, @instance].compact
  end

  def generic_url(prefix="")
    self.send("#{prefix}#{url_prefix}_#{model_name.downcase}_url",
              *url_args)
  end

  def show_url
    generic_url
  end

  def new_url
    generic_url("new_")
  end

  def edit_url
    generic_url("edit_")
  end

  def association_name
    @association_name ||= model_name.downcase.pluralize
  end

  def model_name
    @model_name ||= model.name
  end

  def port_breadcrumb
    add_breadcrumb "Ports", ports_url
    add_breadcrumb "#{@port.name}", port_url(@port)
    if @terminal
      add_breadcrumb "Terminals", port_terminals_url(@port)
      add_breadcrumb @terminal.name, port_terminal_url(@port, @terminal)
    end
    add_breadcrumb model_name, parent_url
  end

  def get_port_and_terminal
    @port = Port.find(params[:port_id])
    @terminal = Terminal.find_by_id(params[:terminal_id])
  end


end
