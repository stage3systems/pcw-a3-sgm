class CommonController < BaseController

  def show
    @title = "View #{model_name}"
    @instance = model_by_id(params[:id])
    add_breadcrumb "#{@instance.name}",
                   send("#{model_name.downcase}_url", @instance)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @instance }
    end
  end

  def new
    @title = "New #{model_name}"
    @instance = model.new
    @instance.tenant_id = current_tenant.id if has_tenant?
    add_breadcrumb "New #{model_name}",
                   send("new_#{model_name.downcase}_url")

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @instance }
    end
  end

  def create
    @title = "New #{model_name}"
    @instance = model.new(safe_params)
    @instance.tenant_id = current_tenant.id if has_tenant?
    add_breadcrumb "New #{model_name}", send("new_#{model_name.downcase}_url")

    form_response(@instance.save, @instance, "created", "new")
  end

  def update
    @title = "Edit #{model_name}"
    @instance = model_by_id(params[:id])
    add_breadcrumb "Edit #{@instance.name}",
                    send("edit_#{model_name.downcase}_url", @instance)

    form_response(@instance.update_attributes(safe_params),
                  @instance, "updated", "edit")
  end

  def edit
    @title = "Edit #{model_name}"
    @instance = model_by_id(params[:id])
    add_breadcrumb "Edit #{@instance.name}",
                    send("edit_#{model_name.downcase}_url", @instance)
  end

  def destroy
    @instance = model_by_id(params[:id])
    @instance.destroy

    respond_to do |format|
      format.html { redirect_to send("#{model_name.downcase.pluralize}_url") }
      format.json { head :no_content }
    end
  end

  private
  def has_tenant?
    not model.columns_hash['tenant_id'].nil?
  end

  def model_by_id(id)
    if has_tenant?
      model.where(tenant_id: current_tenant.id).find(id)
    else
      model.find(id)
    end
  end
end
