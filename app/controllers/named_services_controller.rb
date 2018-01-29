class NamedServicesController < BaseController
  before_filter :authenticate_user!
  before_filter :ensure_admin

  def index
    @instances = Service.where(tenant_id: current_tenant.id,
                               port_id: nil,
                               terminal_id: nil)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @instances }
    end
  end

  def show
    @instance = Service.where(tenant_id: current_tenant.id).find(params[:id])
    add_breadcrumb @instance.name, named_service_url(@instance)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @instance }
    end
  end

  def new
    @instance = Service.new(tenant_id: current_tenant.id)
    add_breadcrumb "New Named Service", new_named_service_path()

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @instance }
    end
  end

  def edit
    @instance = Service.where(tenant_id: current_tenant.id).find(params[:id])
    add_breadcrumb "Edit #{@instance.name}", edit_named_service_path(@instance)
  end

  def create
    @instance = Service.new(safe_params)
    @instance.tenant_id = current_tenant.id
    tax_applies = params["tax_applies"] == "1"
    @instance.code = "{compute: function(ctx) { return 0; }, taxApplies: #{tax_applies}}"

    form_response(@instance.save, named_services_path(), "created", "new")
  end

  def update
    @instance = Service.where(tenant_id: current_tenant.id).find(params[:id])
    @instance.tenant_id = current_tenant.id
    @instance.user = current_user if @instance.user.nil?
    tax_applies = params["service"]["tax_applies"] == "1"
    @instance.code = "{compute: function(ctx) { return 0; }, taxApplies: #{tax_applies}}"

    form_response(@instance.update_attributes(safe_params),
                  named_services_path(), "updated", "edit")
  end

  def destroy
    @instance = Service.where(tenant_id: current_tenant.id).find(params[:id])
    @instance.destroy

    respond_to do |format|
      format.html { redirect_to named_services_path() }
      format.json { head :no_content}
    end
  end

  def safe_params
    params.require(:service).permit(:code, :item, :key, :row_order,
                                    :activity_code_id,
                                    :document, :compulsory)
  end

  def model
    Service
  end
end
