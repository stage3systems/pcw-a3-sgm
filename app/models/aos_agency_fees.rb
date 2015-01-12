class AosAgencyFees
  def self.find(q)
    api = AosApi.new
    fees = []
    api.each('agencyFee', q) do |f|
      fees << self.convert_fee(f)
    end
    fees
  end

  private
  def self.convert_fee(f)
    hint = f['description']
    hint += ' (Port Specific Fee)' if f['portId']
    code = "{compute: function(ctx) {return #{f['amount']};}, taxApplies: true}"
    {
      id: f['id'],
      description: f['title'],
      hint: hint,
      amount: f['amount'],
      code: code
    }
  end
end
