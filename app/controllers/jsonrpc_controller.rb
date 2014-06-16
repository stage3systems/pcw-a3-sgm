class JsonrpcController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def index
    respond_to do |format|
      format.json {
        return if !check_params
        return if !check_method
        return if !check_token
        ret = self.send(params[:method], *params[:params]) rescue error(-32603, "Internal error")
        render json: ret
      }
    end
  end

  def sync(action, entity, data)
    return error(-32000, "Unsupported action") unless ['CREATE', 'MODIFY', 'DELETE'].member? action
    return error(-32001, "Unsupported entity") unless ['cargoType'].member? entity
    classes = {'cargoType' => CargoType}
    k = classes[entity]
    return error(-32001, "Unsupported entity") if k.nil?
    if k.send("aos_#{action.downcase}", data)
      success("ok")
    else
      error(-32002, "Failed to apply action to entity")
    end
  end

  def search(query)
    p = {}
    if query[:port]
      port_ids = Port.where('name ILIKE :name', name: "%#{query[:port]}%")
      p[:port_id] = port_ids unless port_ids.empty?
    end
    if query[:terminal]
      terminal_ids = Terminal.where('name ILIKE :name',
                                    name:"%#{query[:terminal]}%")
      p[:terminal_id] = terminal_ids unless terminal_ids.empty?
    end
    p[:aos_id] = nil unless query[:showRegistered]
    eta = Date.parse(query[:eta]) rescue nil
    das = Disbursement.joins(:current_revision).where(p)
    das = das.where('disbursement_revisions.eta = :eta', eta: eta) if eta
    das = das.where("disbursement_revisions.data -> 'vessel_name' ILIKE ?",
                    "%#{query[:vessel]}%") if query[:vessel]
    count = das.count
    das = das.order('disbursement_revisions.updated_at DESC')
    page = query[:page].to_i
    das = das.offset(page*10).limit(10)
    das = das.select('disbursements.id,
                      disbursement_revisions.reference,
                      disbursements.publication_id,
                      disbursement_revisions.amount,
                      disbursements.status_cd')
    das = das.map do |d|
      {
        "id" => d.id,
        "reference" => d.reference,
        "uuid" => d.publication_id,
        "status" => ["draft", "initial", "deleted", "final"][d.status_cd],
        "amount" => d.amount
      }
    end
    success({
      "disbursements" => das,
      "count" => count,
      "page" => page,
    })
  end

  def register(id, aos_id)
    da = Disbursement.find(id)
    if da.aos_id
      error(-32602, "Already registered")
    else
      da.aos_id = aos_id
      da.save!
      success("ok")
    end
  end

  def unregister(aos_id)
    da = Disbursement.find_by_aos_id(aos_id)
    error(-32602, "Registered DA not found") if da.nil?
    da.aos_id = nil
    da.save!
    success("ok")
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
    return true if ["sync", "search",
                    "register", "unregister"].include? params[:method]
    render json: error(-32601, "Method not found")
    false
  end

  def check_token
    token = params[:params].shift rescue nil
    return true if token == ProformaDA::Application.config.aos_api_psk
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

