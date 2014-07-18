class TaxesController < CommonController
  before_filter :authenticate_user!
  before_filter :ensure_admin

  add_breadcrumb "Taxes", :taxes_url

  # GET /taxes
  # GET /taxes.json
  def index
    @title = "Taxes"
    @taxes_grid = initialize_grid(Tax,
                      order: 'taxes.name',
                      order_direction: 'asc')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  private
  def safe_params
    params.require(:tax).permit(:name, :code, :rate)
  end
end
