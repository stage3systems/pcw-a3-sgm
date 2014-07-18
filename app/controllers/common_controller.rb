class CommonController < ApplicationController

  def show
    @title = "View #{model.name}"
    @instance = model.find(params[:id])
    add_breadcrumb "#{@instance.name}",
                   send("#{model.name.downcase}_url", @instance)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @instance }
    end
  end

  def new
    @title = "New #{model.name}"
    @instance = model.new
    add_breadcrumb "New #{model.name}",
                   send("new_#{model.name.downcase}_url")

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @instance }
    end
  end

  def create
    @title = "New #{model.name}"
    @instance = model.new(safe_params)
    add_breadcrumb "New #{model.name}", send("new_#{model.name.downcase}_url")

    respond_to do |format|
      if @instance.save
        format.html {
          redirect_to @instance,
                      notice: "#{model.name} was successfully created." }
        format.json { render json: @instance, status: :created, location: @instance }
      else
        format.html { render action: "new" }
        format.json { render json: @instance.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @title = "Edit #{model.name}"
    @instance = model.find(params[:id])
    add_breadcrumb "Edit #{@instance.name}",
                    send("edit_#{model.name.downcase}_url", @instance)

    respond_to do |format|
      if @instance.update_attributes(safe_params)
        format.html { redirect_to @instance,
                                  notice: "#{model.name} was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @instance.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @title = "Edit #{model.name}"
    @instance = model.find(params[:id])
    add_breadcrumb "Edit #{@instance.name}",
                    send("edit_#{model.name.downcase}_url", @instance)
  end

  def destroy
    @instance = model.find(params[:id])
    @instance.destroy

    respond_to do |format|
      format.html { redirect_to send("#{model.name.downcase.pluralize}_url") }
      format.json { head :no_content }
    end
  end

end
