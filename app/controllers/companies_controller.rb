class CompaniesController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Companies", :companies_url
  # GET /companies
  # GET /companies.json
  def index
    @companies_grid = initialize_grid(Company,
                        order: 'companies.name',
                        order_direction: 'asc')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
    @company = Company.find(params[:id])
    add_breadcrumb "#{@company.name}", company_url(@company)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @company }
    end
  end

  # GET /companies/new
  # GET /companies/new.json
  def new
    @company = Company.new
    add_breadcrumb "New Company", new_company_url

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @company }
    end
  end

  # GET /companies/1/edit
  def edit
    @company = Company.find(params[:id])
    add_breadcrumb "Edit #{@company.name}", edit_company_url(@company)
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = Company.new(params[:company])
    add_breadcrumb "New Company", new_company_url

    respond_to do |format|
      if @company.save
        format.html { redirect_to @company, notice: 'Company was successfully created.' }
        format.json { render json: @company, status: :created, location: @company }
      else
        format.html { render action: "new" }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /companies/1
  # PUT /companies/1.json
  def update
    @company = Company.find(params[:id])
    add_breadcrumb "Edit #{@company.name}", edit_company_url(@company)

    respond_to do |format|
      if @company.update_attributes(params[:company])
        format.html { redirect_to @company, notice: 'Company was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company = Company.find(params[:id])
    @company.destroy

    respond_to do |format|
      format.html { redirect_to companies_url }
      format.json { head :no_content }
    end
  end
end
