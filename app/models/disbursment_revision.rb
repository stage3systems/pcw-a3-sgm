class DisbursmentRevision < ActiveRecord::Base
  attr_accessible :cargo_qty, :codes, :data, :days_alongside, :descriptions,
                  :disbursment_id, :fields, :loadtime, :number, :reference,
                  :tax_exempt, :tugs_in, :tugs_out, :values, :values_with_tax
  serialize :data, ActiveRecord::Coders::Hstore
  serialize :fields, ActiveRecord::Coders::Hstore
  serialize :descriptions, ActiveRecord::Coders::Hstore
  serialize :codes, ActiveRecord::Coders::Hstore
  serialize :values, ActiveRecord::Coders::Hstore
  serialize :values_with_tax, ActiveRecord::Coders::Hstore
  belongs_to :disbursment

  def field_keys
    self.fields.sort_by {|k,v| v.to_i}.map {|k,i| k}
  end

  def self.next_from_disbursment(disbursment)
    revision = disbursment.current_revision
    rev = new(disbursment_id: disbursment.id)
    if revision.nil?
      rev.number = 1
      rev.crystalize
    else
      rev.number = revision.number+1
      ["cargo_qty", "days_alongside", "loadtime",
       "tugs_in", "tugs_out", "tax_exempt"].each do |k|
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
    p = self.disbursment.port.crystalize
    v = self.disbursment.crystalize_vessel
    c = self.disbursment.company.crystalize
    self.data = v.merge(p[:data]).merge(c)
    self.fields = p[:fields]
    self.descriptions = p[:descriptions]
    self.codes = p[:codes]
    self.values = {}
    self.values_with_tax = {}
  end

  def previous
    self.disbursment.disbursment_revisions.where(:number => self.number-1).first
  end

  def next
    self.disbursment.disbursment_revisions.where(:number => self.number+1).first
  end

  def currency_symbol
    self.data['currency_symbol']
  end

  def amount
    self.data[self.tax_exempt? ? 'total' : 'total_with_tax'].to_f
  end

  def reference
    ref = "#{self.data['vessel_name']}-#{self.data['port_name']}#{ "-"+self.data['terminal_name'] if self.data.has_key? 'terminal_name' }-#{self.updated_at}.#{self.number}"
    ref.upcase.gsub(' ', '_')
  end
end
