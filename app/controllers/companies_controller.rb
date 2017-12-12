class CompaniesController < CommonController
  before_filter :authenticate_user!
  before_filter :ensure_admin, except: [:search]

  add_breadcrumb "Companies", :companies_url

  def model
    Company
  end

  def index
    @title = "Companies"
    @companies_grid = initialize_grid(current_tenant.companies,
                        order: 'companies.name',
                        order_direction: 'asc')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def search
    companies = current_tenant.companies.where(
                  'remote_id is not null and name ilike :name',
                  name: "%#{params[:name]}%").map do |c|
      {id: c.id, remote_id: c.remote_id, name: c.name}
    end
    render json: companies
  end

  private
  def safe_params
    params.require(:company).permit(:email, :name, :is_supplier)
  end
end
