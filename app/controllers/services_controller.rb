class ServicesController < NestedCommonController

  def sort
    @instance = current_tenant.services.find(params[:id])
    @instance.row_order_position = params[:row_order_position]
    @instance.save
    render nothing: true
  end


  private
  def new_instance
    super()
    @instance.code = "{\n  compute: function(ctx) {\n    return 0;\n  },\n  taxApplies: false\n}\n"
    @instance.changelog = 'Initial service definition'
    @instance
  end

  def parse_params
    @old_code = @instance.code rescue ''
    @changelog = params[:service].delete(:changelog)
  end

  def successful_save
    update = ServiceUpdate.new()
    update.tenant_id = current_tenant.id
    update.service = @instance
    update.user = current_user
    update.changelog = @changelog
    update.document = @instance.document if @instance.document.file.exists?
    update.old_code = @old_code
    update.new_code = @instance.code
    update.save!
  end

  def model
    Service
  end

  def safe_params
    params.require(:service).permit(:code, :item, :key, :row_order, :disabled, 
                                    :activity_code_id, :company_id,
                                    :document, :compulsory)
  end
end
