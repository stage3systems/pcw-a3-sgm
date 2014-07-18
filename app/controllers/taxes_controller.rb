class TaxesController < ApplicationController
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

  # GET /taxes/1
  # GET /taxes/1.json
  def show
    @title = "View Tax"
    @tax = Tax.find(params[:id])
    add_breadcrumb "#{@tax.code}", tax_url(@tax)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tax }
    end
  end

  # GET /taxes/new
  # GET /taxes/new.json
  def new
    @title = "New Tax"
    @tax = Tax.new
    add_breadcrumb "New", new_tax_url

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tax }
    end
  end

  # GET /taxes/1/edit
  def edit
    @title = "Edit Tax"
    @tax = Tax.find(params[:id])
    add_breadcrumb "Edit #{@tax.code}", edit_tax_url(@tax)
  end

  # POST /taxes
  # POST /taxes.json
  def create
    @title = "New Tax"
    @tax = Tax.new(tax_params)
    add_breadcrumb "New", new_tax_url

    respond_to do |format|
      if @tax.save
        format.html { redirect_to @tax, notice: 'Tax was successfully created.' }
        format.json { render json: @tax, status: :created, location: @tax }
      else
        format.html { render action: "new" }
        format.json { render json: @tax.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /taxes/1
  # PUT /taxes/1.json
  def update
    @title = "Edit Tax"
    @tax = Tax.find(params[:id])
    add_breadcrumb "Edit #{@tax.code}", edit_tax_url(@tax)

    respond_to do |format|
      if @tax.update_attributes(tax_params)
        format.html { redirect_to @tax, notice: 'Tax was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tax.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /taxes/1
  # DELETE /taxes/1.json
  def destroy
    @tax = Tax.find(params[:id])
    @tax.destroy

    respond_to do |format|
      format.html { redirect_to taxes_url }
      format.json { head :no_content }
    end
  end

  private
  def tax_params
    params.require(:tax).permit(:name, :code, :rate)
  end
end
