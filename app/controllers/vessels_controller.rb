class VesselsController < CommonController
  before_filter :authenticate_user!
  before_filter :ensure_admin, except: [:search]

  add_breadcrumb "Vessels", :vessels_url

  def model
    Vessel
  end

  # GET /vessels
  # GET /vessels.json
  def index
    @title = "Vessels"
    @vessels_grid = initialize_grid(current_tenant.vessels,
                      order: 'vessels.name',
                      order_direction: 'asc')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def search
    vessels = current_tenant.vessels
                .where('name ilike :name',
                       name: "%#{params[:name]}%").map do |v|
      {id: v.id, name: v.name}
    end
    render json: vessels
  end

  private
  def safe_params
    params.require(:vessel).permit(:dwt, :grt, :loa, :nrt, :name, :sbt_certified)
  end
end
