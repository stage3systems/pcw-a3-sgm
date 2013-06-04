class TariffsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :ensure_admin

  def index
    get_port_and_terminal
    port_breadcrumb
    if @terminal
      @tariffs = @terminal.tariffs.all
    else
      @tariffs = @port.tariffs.all
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tariffs }
    end
  end

  def show
    get_port_and_terminal
    @tariff = Tariff.find(params[:id])
    port_breadcrumb
    if @terminal
      add_breadcrumb @tariff.name, port_terminal_tariff_url(@port, @terminal, @tariff)
    else
      add_breadcrumb @tariff.name, port_tariff_url(@port, @tariff)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tariff }
    end
  end

  def new
    get_port_and_terminal
    @tariff = Tariff.new
    @tariff.port = @port
    @tariff.terminal = @terminal
    port_breadcrumb
    if @terminal
      add_breadcrumb "New Tariff", new_port_terminal_tariff_url(@port, @terminal)
    else
      add_breadcrumb "New Tariff", new_port_tariff_url(@port)
    end


    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tariff }
    end
  end

  def edit
    get_port_and_terminal
    @tariff = Tariff.find(params[:id])
    port_breadcrumb
    if @terminal
      add_breadcrumb "Edit #{@tariff.name}", edit_port_terminal_tariff_url(@port, @terminal, @tariff)
    else
      add_breadcrumb "Edit #{@tariff.name}", edit_port_tariff_url(@port, @tariff)
    end
  end

  def create
    get_port_and_terminal
    @tariff = Tariff.new(params[:tariff])
    @tariff.port = @port
    @tariff.terminal = @terminal
    port_breadcrumb
    if @terminal
      add_breadcrumb "New Tariff", new_port_terminal_tariff_url(@port, @terminal)
    else
      add_breadcrumb "New Tariff", new_port_tariff_url(@port)
    end

    respond_to do |format|
      if @tariff.save
        format.html {
          if @terminal
            notice = 'Tariff was successfully created.'
            redirect_to port_terminal_tariffs_path(@port, @terminal), notice: notice
          else
            redirect_to port_tariffs_path(@port), notice: notice
          end
        }
        format.json { render json: @tariff, status: :created, location: @tariff }
      else
        format.html { render action: "new" }
        format.json { render json: @tariff.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    get_port_and_terminal
    @tariff = Tariff.find(params[:id])

    respond_to do |format|
      if @tariff.update_attributes(params[:tariff])
        format.html {
          notice = 'Tariff was successfully updated.'
          if @terminal
            redirect_to port_terminal_tariffs_path(@port, @terminal), notice: notice
          else
            redirect_to port_tariffs_path(@port), notice: notice
          end
        }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tariff.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    get_port_and_terminal
    @tariff = Tariff.find(params[:id])
    @tariff.destroy

    respond_to do |format|
      format.html {
        if @terminal
          redirect_to port_terminal_tariffs_path(@port, @terminal)
        else
          redirect_to port_tariffs_path(@port)
        end
      }
      format.json { head :no_content }
    end
  end
  private

  def get_port_and_terminal
    @port = Port.find(params[:port_id])
    @terminal = Terminal.find_by_id(params[:terminal_id])
  end

  def port_breadcrumb
    add_breadcrumb "Ports", ports_url
    add_breadcrumb "#{@port.name}", port_url(@port)
    if @terminal
      add_breadcrumb "Terminals", port_terminals_url(@port)
      add_breadcrumb @terminal.name, port_terminal_url(@port, @terminal)
      add_breadcrumb "Tariffs", port_terminal_tariffs_url(@port, @terminal)
    else
      add_breadcrumb "Tariffs", port_tariffs_url(@port)
    end
  end
end
