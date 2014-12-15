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
      "comments" => {}
    }
    i = offset
    @api.each('agencyFee', {companyId: @disbursement.company.remote_id}) do |f|
      if f['portId'].nil? or f['portId'] == @disbursement.port.remote_id
        key = "AGENCY_FEE_#{f['id']}"
        fees["fields"][key] = i
        fees["compulsory"][key] = false
        c = "{compute: function(ctx) {return #{f['amount']};}, taxApplies: true}"
        fees["codes"][key] = c
        fees["descriptions"][key] = f['title']
        fees["comments"][key] = f['description']
        i += 1
      end
    end
    fees
  end
end
