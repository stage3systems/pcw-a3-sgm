var parseCodes = function(ctx) {
  var n = ctx.services.length,
      i = -1;
  while (++i < n) {
    var k = ctx.services[i];
    ctx.parsed_codes[k] = eval("("+ctx.codes[k]+")");
  }
};
var normalizeValue = function(val) {
  if (isNaN(val)) {
    return "0.00";
  }
  return parseFloat(val).toFixed(2);
};
var compute = function(ctx) {
  var total = 0,
      totalTaxInc = 0,
      n = ctx.services.length,
      i = -1;
  while (++i < n) {
    var key = ctx.services[i];
    var code = ctx.parsed_codes[key];
    if (!code) continue;
    var val = ctx.computed[key] = normalizeValue(code.compute(ctx));
    if (key in ctx.overriden) {
      val = normalizeValue(ctx.overriden[key]);
    }
    ctx.values[key] = val;
    if (val == "NaN") {
      ctx.values_with_tax[key] = "NaN";
      continue;
    }
    val = parseFloat(val);
    if (ctx.compulsory[key] || !ctx.disabled[key]) total += val;
    var valTaxInc = val;
    var taxRate = parseFloat(code.taxRate ? code.taxRate : ctx.tax_rate);
    if (code.taxApplies) valTaxInc = val*taxRate;
    ctx.values_with_tax[key] = valTaxInc.toFixed(2);
    if (ctx.compulsory[key] || !ctx.disabled[key]) totalTaxInc += valTaxInc;
    ctx.total = normalizeValue(total);
    ctx.totalTaxInc = normalizeValue(totalTaxInc);
  }
};
