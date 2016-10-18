class JsonrpcController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def index
    respond_to do |format|
      format.json {
        return if !check_params
        return if !check_method
        return if !check_token
        ret = self.send(params[:method], *params[:params]) #rescue error(-32603, "Internal error")
        render json: ret
      }
    end
  end

  def sync(action, entity, data)
    return error(-32000, "Unsupported action") unless ['CREATE', 'MODIFY', 'DELETE'].member? action
    classes = {
      'cargoType' => CargoType,
      'port' => Port,
      'person' => User,
      'company' => Company,
      'office' => Office,
      'vessel' => Vessel,
      'emailAddress' => EmailAddress,
      'activityCode' => ActivityCode,
      'activity' => ActivityCode,
      'officePort' => OfficePort
    }
    k = classes[entity]
    return error(-32001, "Unsupported entity") if k.nil?
    if k.send("aos_#{action.downcase}", current_tenant, data)
      success("ok")
    else
      error(-32002, "Failed to apply action to entity")
    end
  end

  private
  def check_params
    if params[:method].nil? or params[:params].nil? or params[:id].nil?
      render json: error(-32600, "Invalid request")
      return false
    end
    true
  end

  def check_method
    return true if ["sync"].include? params[:method]
    render json: error(-32601, "Method not found")
    false
  end

  def check_token
    token = params[:params].shift rescue nil
    return true if current_tenant.aos_api_psk and token == current_tenant.aos_api_psk
    render json: error(-32000, "Invalid token")
    false
  end

  def error(code, message)
    r = resp
    r["error"] = {"code" => code, "message" => message}
    r
  end

  def success(result)
    r = resp
    r["result"] = result
    r
  end

  def resp
    r = {"jsonrpc" => "2.0"}
    r["id"] = params[:id] if params[:id]
    r
  end
end
