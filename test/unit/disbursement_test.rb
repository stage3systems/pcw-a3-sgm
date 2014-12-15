require 'test_helper'

class DisbursementTest < ActiveSupport::TestCase
  def setup
    @newcastle = ports(:newcastle)
    @brisbane = ports(:brisbane)
    @stage3 = companies(:stage3)
    @feecompany = companies(:feecompany)
    aos_stub(:get, "agencyFee?companyId=654", :agencyFee, [
      {id: 1,
       amount: "1000.0",
       title: "First fee",
       description: "Agency Fee One",
       portId: nil},
      {id: 2,
       amount: "2000.0",
       title: "Second fee",
       description: "Agency Fee Two",
       portId: @brisbane.remote_id},
      {id: 3,
       amount: "3000.0",
       title: "Third fee",
       description: "Agency Fee Three",
       portId: @newcastle.remote_id}
    ])
  end

  def disbursement(port, company=@stage3)
    d = Disbursement.new
    d.port = port
    d.company = company
    d.tbn = true
    d.dwt = 1
    d.grt = 1
    d.nrt = 1
    d.loa = 1
    d
  end

  test "first revision is automatically created" do
    aos_stub(:get, "agencyFee?companyId=", :agencyFee, [])
    d = self.disbursement(@newcastle)
    assert d.save
    assert_not_nil d.current_revision
    assert d.current_revision.number == 0
  end

  test "the first revision totals are computed" do
    aos_stub(:get, "agencyFee?companyId=", :agencyFee, [])
    d = self.disbursement(@brisbane)
    assert d.save
    assert d.current_revision.data["total"] == "3000.00"
    assert d.current_revision.data["total_with_tax"] == "3300.00"
  end

  test "the context is taken into account" do
    aos_stub(:get, "agencyFee?companyId=", :agencyFee, [])
    d = self.disbursement(@brisbane)
    assert d.save
    r = d.current_revision
    r.tugs_in = 2
    r.compute
    assert r.data["total"] == "5000.00"
    assert r.data["total_with_tax"] == "5500.00"
    r.tugs_in = 4
    r.compute
    assert r.data["total"] == "7000.00"
    assert r.data["total_with_tax"] == "7700.00"
  end

  test "computed values can be overriden" do
    aos_stub(:get, "agencyFee?companyId=", :agencyFee, [])
    d = self.disbursement(@brisbane)
    assert d.save
    r = d.current_revision
    r.overriden['MNL'] = "12000.00";
    r.compute
    assert r.data["total"] == "14000.00"
    assert r.data["total_with_tax"] == "15400.00"
  end

  test "overriden values are persisted across revisions" do
    aos_stub(:get, "agencyFee?companyId=", :agencyFee, [])
    d = self.disbursement(@brisbane)
    assert d.save
    r = d.current_revision
    r.overriden['MNL'] = "12000.00";
    r.compute
    assert r.data["total"] == "14000.00"
    assert r.data["total_with_tax"] == "15400.00"
    r.save
    r2 = d.next_revision
    assert r2.number == 1
    assert r2.data["total"] == "14000.00"
    assert r2.data["total_with_tax"] == "15400.00"
    r2.fields['EXTRAITEM1'] = (r.fields.values.max.to_i+1).to_s
    r2.codes['EXTRAITEM1'] = '{compute: function(ctx) { return 0;},taxApplies: true}'
    r2.overriden['EXTRAITEM1'] = "1000.00"
    r2.compulsory['EXTRAITEM1'] = "0"
    r2.disabled['EXTRAITEM1'] = "0"
    r2.compute
    r2.save
    d.current_revision = r2
    d.save
    d.reload
    r3 = d.next_revision
    assert_equal(2, r3.number)
    assert r3.data["total"] == "15000.00"
    assert r3.data["total_with_tax"] == "16500.00"
  end

  test "disabled fields are ignored only when not compulsory" do
    aos_stub(:get, "agencyFee?companyId=", :agencyFee, [])
    d = self.disbursement(@brisbane)
    assert d.save
    r = d.current_revision
    # add a custom field
    r.fields['EXTRAITEM1'] = (r.fields.values.max.to_i+1).to_s
    r.codes['EXTRAITEM1'] = '{compute: function(ctx) { return 0;},taxApplies: true}'
    r.overriden['EXTRAITEM1'] = "1000.00"
    r.compulsory['EXTRAITEM1'] = "0"
    r.disabled['EXTRAITEM1'] = "0"
    r.compute
    assert r.data["total"] == "4000.00"
    assert r.data["total_with_tax"] == "4400.00"
    r.disabled['EXTRAITEM1'] = "1"
    r.compute
    assert r.data["total"] == "3000.00"
    assert r.data["total_with_tax"] == "3300.00"
    r.compulsory['EXTRAITEM1'] = "1"
    r.compute
    assert r.data["total"] == "4000.00"
    assert r.data["total_with_tax"] == "4400.00"
  end

  test "company fees are inserted" do
    d = self.disbursement(@brisbane, @feecompany)
    assert d.save
    r = d.current_revision
    assert r.data["total"] == "6000.00"
    assert r.data["total_with_tax"] == "6600.00"
    assert r.descriptions['AGENCY_FEE_1'] == 'First fee'
    assert r.descriptions['AGENCY_FEE_2'] == 'Second fee'
    assert r.descriptions['AGENCY_FEE_3'] == nil
  end

  test "company fees can be disabled" do
    d = self.disbursement(@brisbane, @feecompany)
    assert d.save
    r = d.current_revision
    assert r.data["total"] == "6000.00"
    assert r.data["total_with_tax"] == "6600.00"
    r.disabled['AGENCY_FEE_1'] = "1"
    r.compute
    assert r.data["total"] == "5000.00"
    assert r.data["total_with_tax"] == "5500.00"
  end

  test "company fees can be overriden" do
    d = self.disbursement(@brisbane, @feecompany)
    assert d.save
    r = d.current_revision
    assert r.data["total"] == "6000.00"
    assert r.data["total_with_tax"] == "6600.00"
    r.overriden['AGENCY_FEE_1'] = "2000.00"
    r.compute
    assert r.data["total"] == "7000.00"
    assert r.data["total_with_tax"] == "7700.00"
  end

  test "blank disbursements have no charges" do
    aos_stub(:get, "agencyFee?companyId=", :agencyFee, [])
    d = self.disbursement(@brisbane)
    d.blank!
    d.save
    r = d.current_revision
    assert r.data["total"] == "0.0"
    assert r.data["total_with_tax"] == "0.0"
    assert r.amount == 0.0
  end
end
