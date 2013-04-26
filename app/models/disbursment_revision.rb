class DisbursmentRevision < ActiveRecord::Base
  attr_accessible :cargo_qty, :codes, :data, :days_alongside, :descriptions,
                  :disbursment_id, :fields, :loadtime, :number, :reference,
                  :tax_exempt, :tugs_in, :tugs_out, :values, :values_with_tax,
                  :cargo_type_id, :comments
  serialize :data, ActiveRecord::Coders::Hstore
  serialize :fields, ActiveRecord::Coders::Hstore
  serialize :descriptions, ActiveRecord::Coders::Hstore
  serialize :comments, ActiveRecord::Coders::Hstore
  serialize :codes, ActiveRecord::Coders::Hstore
  serialize :values, ActiveRecord::Coders::Hstore
  serialize :values_with_tax, ActiveRecord::Coders::Hstore
  belongs_to :disbursment
  belongs_to :cargo_type

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
       "tugs_in", "tugs_out", "tax_exempt", "cargo_type_id"].each do |k|
        rev.send("#{k}=", revision.send(k))
      end
      rev.crystalize
      total = BigDecimal.new("0")
      total_with_tax = BigDecimal.new("0")
      disabled = []
      revision.fields.keys.each do |k|
        if k.starts_with? "EXTRAITEM"
          rev.fields[k] = rev.fields.values.map {|v| v.to_i}.max+1
          rev.codes[k] = revision.codes[k]
          rev.descriptions[k] = revision.descriptions[k]
        end
        if rev.fields.has_key?(k)
          value = revision.values[k]
          rev.values[k] = value
          value_with_tax = revision.values_with_tax[k]
          rev.values_with_tax[k] = value_with_tax
          rev.comments[k] = revision.comments[k] if revision.comments
          if revision.disabled[k]
            disabled << k
          else
            total_with_tax += BigDecimal.new((value_with_tax or "0"))
            total += BigDecimal.new((value or "0"))
          end
        end
      end
      rev.data["disabled"] = disabled.join(',')
      rev.data["total"] = total.round(2).to_s
      rev.data["total_with_tax"] = total_with_tax.round(2).to_s
    end
    rev.save
    rev
  end

  def disabled
    @disabled ||= begin
      disabled = self.data['disabled'].split(',') rescue []
      hash = {}
      self.fields.keys.each do |f|
        hash[f] = disabled.member?(f)
      end
      hash
    end
  end

  def crystalize
    p = self.disbursment.port.crystalize
    v = self.disbursment.crystalize_vessel
    c = self.disbursment.company.crystalize
    conf = Configuration.last.crystalize
    t = self.disbursment.terminal.crystalize(p[:fields].values.map{|v|v.to_i}.max+1) rescue {data: {}, fields: {}, descriptions: {}, codes: {}}
    ct = self.cargo_type.crystalize rescue {}
    self.data = v.merge(p[:data]).merge(c).merge(conf).merge(t[:data]).merge(ct)
    self.fields = p[:fields].merge(t[:fields])
    self.descriptions = p[:descriptions].merge(t[:descriptions])
    self.codes = p[:codes].merge(t[:codes])
    self.values = {}
    self.values_with_tax = {}
    self.comments = {}
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
    ref = "#{self.data['vessel_name']} - #{self.data['port_name']}#{ " - "+self.data['terminal_name'] if self.data.has_key? 'terminal_name' } - #{self.updated_at.to_date} - r#{self.number}"
    #ref.upcase.gsub(' ', '-')
  end
end
