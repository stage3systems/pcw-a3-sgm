class ComputationContext < V8::Context

  def initialize(revision)
    super()
    @revision = revision
    build_context
  end

  def compute
    @revision.data["total"] = total
    @revision.data["total_with_tax"] = total_with_tax
    @revision.fields.keys.each do |k|
      @revision.values[k] = value_for(k)
      @revision.values_with_tax[k] = value_with_tax_for(k)
    end
  end

  private
  def build_context
    self.eval(@revision.context)
    self.load(Rails::root.join("app/assets/javascripts/compute.js"))
    self.eval("parseCodes(ctx)");
    self.eval("compute(ctx)");
  end

  def total
    self.eval("ctx.total") || 0.0
  end

  def total_with_tax
    self.eval("ctx.totalTaxInc") || 0.0
  end

  def value_for(k)
    self.eval("ctx.values['#{k}']")
  end

  def value_with_tax_for(k)
    self.eval("ctx.values_with_tax['#{k}']")
  end

end
