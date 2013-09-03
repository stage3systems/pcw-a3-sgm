require 'test_helper'

class DisbursementTest < ActiveSupport::TestCase
  def setup
    @newcastle = ports(:newcastle)
    @brisbane = ports(:brisbane)
    @stage3 = companies(:stage3)
  end

  def disbursement(port)
    d = Disbursement.new
    d.port = port
    d.company = @stage3
    d.tbn = true
    d.dwt = 1
    d.grt = 1
    d.nrt = 1
    d.loa = 1
    d
  end

  test "first revision is automatically created" do
    d = self.disbursement(@newcastle)
    assert d.save
    assert_not_nil d.current_revision
    assert d.current_revision.number == 0
    assert d.current_revision.amount == 0
  end

  test "the first revision totals are computed" do
    d = self.disbursement(@brisbane)
    assert d.save
    assert d.current_revision.data["total"] == "3000.00"
    assert d.current_revision.data["total_with_tax"] == "3300.00"
  end

  test "the context is taken into account" do
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
    d = self.disbursement(@brisbane)
    assert d.save
    r = d.current_revision
    r.overriden['MNL'] = "12000.00";
    r.compute
    assert r.data["total"] == "14000.00"
    assert r.data["total_with_tax"] == "15400.00"
  end

  test "overriden values are persisted across revisions" do
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
    d.reload
    r3 = d.next_revision
    assert r3.number == 2
    assert r3.data["total"] == "15000.00"
    assert r3.data["total_with_tax"] == "16500.00"
  end

  test "disabled fields are ignored only when not compulsory" do
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
end
