class BaseController < ApplicationController
  private
  def form_response(success, success_url, operation, error_action)
    respond_to do |format|
      if success
        successful_save
        format.html {
          redirect_to success_url,
                      notice: "#{model_name} was successfully #{operation}."
        }
        format.json { render json: @instance, status: :created, location: @instance }
      else
        format.html { render action: error_action }
        format.json { render json: @instance.errors, status: :unprocessable_entity }
      end
    end
  end

  def successful_save
  end

  def model_name
    @model_name ||= model.name
  end
end
