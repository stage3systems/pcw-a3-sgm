require 'test_helper'

class FundingAgreementTest < ActiveSupport::TestCase
  def setup
    @vessel = vessels(:vesselone)
    @port = ports(:newcastle)
    @tenant = tenants(:one)
  end

  def setup_da(company_name)
    date = Date.today
    da = Disbursement.new
    da.tenant = @tenant
    da.port = @port
    da.vessel = @vessel
    da.company = companies(company_name)
    aos_stub(:get,
             "agencyFee?companyId=#{da.company.remote_id}&dateEffectiveEnd=#{date}&"+
             "dateExpiresStart=#{date}&portId=#{@port.remote_id}",
             :agencyFee, [])
    da.save
    da
  end

  def exercise_company(company_name)
    aos_stub(:get, 'agencyFee?companyId=', :agencyFee, [])
    da = setup_da(company_name)
    [:initial, :close, :inquiry].each do |status|
      da.send("#{status}!")
      da.save!
      da.reload
      r = da.current_revision
      r.compute
      r.save
      doc = DisbursementDocument.new(da,r)
      fa = FundingAgreement.new(doc)
      if da.inquiry?
        assert doc.prefunding.empty?
      else
        assert_not doc.prefunding.empty?
      end
      assert_not fa.conditions.empty?
    end
    da.destroy
  end

  test "all supported funding agreements" do
    [:unset_funding, :no_funding,
     :percent_on_close, :percent_on_berth,
     :percent_on_berth_100,
     :less_agency_fee_on_berth].each do |c|
      exercise_company(c)
    end
  end
end
