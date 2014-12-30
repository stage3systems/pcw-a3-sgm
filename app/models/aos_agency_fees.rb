class AosAgencyFees
  def initialize(disbursement)
   @api = AosApi.new
   @disbursement = disbursement
  end

  def crystalize(offset=0)
    fees = {
      "fields" => {},
      "descriptions" => {},
      "codes" => {},
      "compulsory" => {},
      "hints" => {}
    }
    return fees unless @disbursement.company
    i = offset
    @api.each('agencyFee', {companyId: @disbursement.company.remote_id}) do |f|
      port_id = f['portId']
      if port_id.nil? or port_id == @disbursement.port.remote_id
        key = "AGENCY-FEE-#{f['id']}"
        fees["fields"][key] = i
        fees["compulsory"][key] = false
        fees["codes"][key] = make_js(f['amount'])
        fees["descriptions"][key] = f['title']
        hint = f['description']
        hint += ' (Port Specific Fee)' if port_id
        fees["hints"][key] = hint
        i += 1
      end
    end
    fees
  end

  private
  def make_js(amount)
    "{compute: function(ctx) {return #{amount};}, taxApplies: true}"
  end
end
