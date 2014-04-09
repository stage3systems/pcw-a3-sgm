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
                      disbursements.status_cd')
    das = das.map do |d|
      {
        "id" => d.id,
        "reference" => d.reference,
        "uuid" => d.publication_id,
        "status" => ["draft", "initial", "deleted", "final"][d.status_cd]
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
    da.aos_id = aos_id
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
    return true if ["search", "register"].include? params[:method]
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

