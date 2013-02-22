class EstimateRevision < ActiveRecord::Base
  attr_accessible :codes, :data, :descriptions, :estimate_id,
                  :fields, :number, :values, :values_with_tax,
                  :cargo_qty, :days_alongside, :loadtime,
                  :tugs_in, :tugs_out
  serialize :data, ActiveRecord::Coders::Hstore
  serialize :fields, ActiveRecord::Coders::Hstore
  serialize :descriptions, ActiveRecord::Coders::Hstore
  serialize :codes, ActiveRecord::Coders::Hstore
  serialize :values, ActiveRecord::Coders::Hstore
  serialize :values_with_tax, ActiveRecord::Coders::Hstore
  belongs_to :estimate
  
  def field_keys
    self.fields.sort_by {|k,v| v.to_i}.map {|k,i| k}
  end

  def self.next_from_estimate(estimate)
    revision = estimate.current_revision
    rev = new(estimate_id: estimate.id)
    if revision.nil?
      rev.number = 1
      rev.crystalize
    else
      rev.number = revision.number+1
      ["cargo_qty", "days_alongside", "loadtime", "tugs_in", "tugs_out"].each do |k|
        rev.send("#{k}=", revision.send(k))
      end
      rev.crystalize
      total = BigDecimal.new("0")
      total_with_tax = BigDecimal.new("0")
      revision.fields.keys.each do |k|
        if rev.fields.has_key?(k) 
          value = revision.values[k]
          rev.values[k] = value
          total += BigDecimal.new(value)
          value_with_tax = revision.values_with_tax[k]
          rev.values_with_tax[k] = value_with_tax
          total_with_tax += BigDecimal.new(value_with_tax)
        end
      end
      rev.data["total"] = total.round(2).to_s
      rev.data["total_with_tax"] = total_with_tax.round(2).to_s
    end
    rev.save
    rev
  end

  def crystalize
    p = self.estimate.port.crystalize
    v = self.estimate.vessel.crystalize
    self.data = v.merge(p[:data])
    self.fields = p[:fields]
    self.descriptions = p[:descriptions]
    self.codes = p[:codes]
    self.values = {}
    self.values_with_tax = {}
  end

  def previous
    self.estimate.estimate_revisions.where(:number => self.number-1).first
  end

  def next
    self.estimate.estimate_revisions.where(:number => self.number+1).first
  end

end
