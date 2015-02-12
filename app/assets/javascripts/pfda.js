$.fn.editable.defaults.mode = 'inline';

var rebuildTable = function(ctx) {
  var $tbody = $('table.disbursement tbody');
  $tbody.empty();
  _.each(ctx.services, function(s) {
    var $tr = $('<tr class="service"></tr>');
    $tr.attr('id', 'service_'+s);
    if (ctx.disabled[s]) {
      $tr.addClass('muted');
    }
    $tr.append('<td><span class="fa fa-sort"></span></td>');
    $tr.append(typeCell(ctx, s));
    $tr.append(nameCell(ctx, s));
    $tr.append(amountCell(ctx, s));
    $tr.append(taxAmountCell(ctx, s));
    $tr.append(disableCell(ctx, s));
    $tbody.append($tr);
  });
  setTimeout(function() {
    displayTaxExempt();
    updateTable(ctx);
    setupDisableListeners(ctx);
    setupSortable();
    computeOrder();
  }, 0);
};


var setupSortable = function(ctx) {
  $('table.disbursement tbody').sortable({
    handle: 'td:first',
    update: computeOrder
  }).disableSelection();
};

var computeOrder = function() {
  $('table.disbursement tbody tr').each(function(i, e) {
    var key = $(e).attr('id').split('_')[1];
    $('input[name="order_'+key+'"]').val(i);
  });
};

var setupDisableListeners = function(ctx) {
  $("input.disable").on("change", function(e) {
    var key = $(e.target).attr("name").split('_')[1],
    disabled = $(e.target).is(":checked");
    if (disabled) {
      $('tr.service#service_'+key).addClass('muted');
    } else {
      $('tr.service#service_'+key).removeClass('muted');
    }
    $('input[name="disabled_'+key+'"]').val(disabled ? "1" : "0");
    ctx.disabled[key] = disabled;
    updateTable(ctx);
  });
};

var updateTable = function(ctx) {
    ctx.estimate.eta = new Date($("input#disbursement_revision_eta").val());
    ctx.estimate.cargo_qty = parseInt($("input#disbursement_revision_cargo_qty").val());
    ctx.estimate.tugs_in = parseInt($("input#disbursement_revision_tugs_in").val());
    ctx.estimate.tugs_out = parseInt($("input#disbursement_revision_tugs_out").val());
    ctx.estimate.loadtime = parseInt($("input#disbursement_revision_loadtime").val());
    ctx.estimate.days_alongside = parseFloat($("input#disbursement_revision_days_alongside").val());
    parseCodes(ctx);
    compute(ctx);
    var n = ctx.services.length,
        i = -1;
    while (++i < n) {
      var key = ctx.services[i];
      $("td#service_"+key+" a").html(convert(ctx.values[key]));
      $("td#service_"+key+" a").attr("data-value", ctx.values[key]);
      $("td#service_with_tax_"+key).html(convert(ctx.values_with_tax[key]));
      $('input[name="value_'+key+'"]').val(ctx.values[key]);
      $('input[name="value_with_tax_'+key+'"]').val(ctx.values_with_tax[key]);
      if ((key in ctx.overriden) && key.indexOf("EXTRAITEM") !== 0) {
        $("td#service_"+key+" i").removeClass("hidden");
        $("td#service_"+key+" a").addClass("editable-unsaved");
      }
    }
    $("th.total").html(convert(ctx.total));
    $("th.total_tax_inc").html(convert(ctx.totalTaxInc));
    $("th span.editable_value").editable({
          display: function(value, sourceData) {
                      var key = $(this).attr("id").split("_")[1];
                      $(this).html(value);
                      ctx.comments[key] = value;
                      $('input[name="comment_'+key+'"]').val(value);
                      },
          emptytext: 'Click to add Comment'
    });
    var valueDisplay = function(value, sourceData) {
      var key = $(this).attr("id").split("_")[1];
      var val = normalizeValue(value);
      if (ctx.computed[key] != val) {
        ctx.overriden[key] = val;
        $('input[name="overriden_'+key+'"]').val(val);
      }
      $(this).html(convert(val));
      setTimeout(function() { updateTable(ctx); }, 0);
    };
    $("td a.editable_value").editable({display: valueDisplay, defaultValue: 0});
};

var deleteService = function(ctx, k) {
  _.each(['codes', 'descriptions', 'hints',
          'values', 'values_with_tax', 'compulsory',
          'disabled', 'overriden'], function(m) {
    delete ctx[m][k];
  });
  ctx.services = _.difference(ctx.services, [k]);
};

var updateAgencyFees = function(ctx, fees) {
  var agencyFeeKeys = _.filter(ctx.services, isAgencyFee);
  // backup existing fees
  var agencyFeesByDesc = _.foldl(agencyFeeKeys, function(acc, k) {
    acc[ctx.descriptions[k]] = {
      key: k,
      comment: ctx.comments[k],
      overriden: ctx.overriden[k],
      disabled: ctx.disabled[k]
    };
    return acc;
  }, {});
  // delete old fees
  _.each(agencyFeeKeys, function(k) { deleteService(ctx, k); });
  // add new fees
  _.each(fees, function(fee) {
    var key = 'AGENCY-FEE-'+fee.id;
    ctx.services.push(key);
    ctx.codes[key] = '{compute: function(ctx) {return '+
                     fee.amount+';},taxApplies: true}';
    ctx.descriptions[key] = fee.description;
    ctx.hints[key] = fee.hint;
    ctx.compulsory[key] = false;
    var migratedFee = agencyFeesByDesc[fee.description];
    if (migratedFee) {
      ctx.comments[key] = migratedFee.comment;
      if (typeof(migratedFee.overriden) !== 'undefined') {
        ctx.overriden[key] = migratedFee.overriden;
      }
      ctx.disabled[key] = migratedFee.disabled;
    }
  });
};

var isExtraItem = function(s) {
  return s.indexOf('EXTRAITEM') === 0;
};

var isAgencyFee = function(s) {
  return s.indexOf('AGENCY-FEE') === 0;
};

var nameCell = function(ctx, s) {
  var $th = $('<th></th>');
  var $descriptionSpan = $('<span class="description">'+
                           ctx.descriptions[s]+'</span>');
  $th.append($descriptionSpan);
  if (isExtraItem(s)) {
    $th.append('&nbsp;');
    $th.append('<i class="glyphicon glyphicon-remove-circle" '+
               'onClick="removeExtra(\''+s+'\')"></i>');
  }
  $th.append('&nbsp;');
  var comment =  ctx.comments[s];
  $commentSpan = $('<span class="editable_value"></span>');
  $commentSpan.attr('id', 'comment_'+s);
  if (comment) {
    $commentSpan.text(comment);
  }
  $th.append($commentSpan);
  var hint = ctx.hints ? ctx.hints[s] : null;
  if (hint) {
    $th.append('<div class="hint">'+hint+'</div>');
  }
  return $th;
};

var typeCell = function(ctx, s) {
  var $td = $('<td></td>'),
      $span = $('<span class="label"></span>');
  if (isExtraItem(s)) {
    $span.addClass('label-success');
    $span.text('Extra Item');
  } else if (isAgencyFee(s)) {
    $span.addClass('label-primary');
    $span.text('Agency Fee');
  } else {
    $span.addClass('label-default');
    $span.text('Port/Terminal Charge');
  }
  return $td.append($span);
};

var amountCell = function(ctx, s) {
  var $td = $('<td></td>');
  $td.attr('id', 'service_'+s);
  var $a = $('<a class="editable_value" href="#" '+
             'title="Click to override"></a>');
  $a.attr('id', 'field_'+s);
  $td.append($a);
  $td.append('&nbsp;');
  $td.append('<i class="hidden glyphicon glyphicon-remove-circle" '+
             'onclick="revertValue(\''+s+'\')"></i>');
  var $overriden = $('<input type="hidden">');
  $overriden.attr('name', 'overriden_'+s);
  var overriden = ctx.overriden[s];
  if (overriden) {
    $overriden.val(overriden);
  }
  $td.append($overriden);
  $td.append('<input type="hidden" name="value_'+s+'">');
  $td.append('<input type="hidden" name="order_'+s+'">');
  $td.append('<input type="hidden" name="value_with_tax_'+s+'">');
  if (isExtraItem(s)) {
    $td.append('<input type="hidden" name="description_'+s+'" '+
               'value="'+ctx.descriptions[s]+'">');
  }
  var $comment = $('<input type="hidden" name="comment_'+s+'">');
  $comment.val(ctx.comments[s]);
  $td.append($comment);
  var $disabled = $('<input type="hidden" name="disabled_'+s+'">');
  $disabled.val(ctx.disabled[s] ? '1' : '0');
  $td.append($disabled);
  return $td;
};

var taxAmountCell = function(ctx, s) {
  var $td = $('<td class="tax"></td>');
  $td.attr('id', 'service_with_tax_'+s);
  return $td;
};

var disableCell = function(ctx, s) {
  var $td = $('<td></td>');
  if (!ctx.compulsory[s]) {
    var $disabled = $('<input class="disable" '+
                      'type="checkbox" name="disable_'+s+'">');
    $disabled.prop('checked', ctx.disabled[s]);
    $td.append($disabled);
  }
  return $td;
};

var displayTaxExempt = function() {
  var taxExempt = $("input#disbursement_revision_tax_exempt").is(':checked');
  if (taxExempt) {
    $(".tax").hide();
  } else {
    $(".tax").show();
  }
};

var setupDA = function(pfda, ctx) {
  var uuid = function() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
        return v.toString(16);
    });
  };
  window.revertValue = function(key) {
    $("td#service_"+key+" a").editable('setValue', ctx.computed[key]);
    delete ctx.values[key];
    delete ctx.overriden[key];
    $('input[name="overriden_'+key+'"]').val('');
    $("td#service_"+key+" a.editable_value").removeClass("editable-unsaved");
    $("td#service_"+key+" i").addClass("hidden");
    update();
  };

  window.removeExtra = function(key) {
    $("tr#service_"+key).remove();
    ctx.services = $.grep(ctx.services, function(value) {
      return value != key;
    });
    update();
  };
  function update() {
    updateTable(ctx);
  }
  var cleanCompute = function() {
    $("a.editable_value").removeClass("editable-unsaved");
    update();
  };

  var handleTaxExempt = function() {
    displayTaxExempt();
    update();
  };
  $("input#disbursement_revision_cargo_qty").on("change", cleanCompute);
  $("input#disbursement_revision_tugs_in").on("change", cleanCompute);
  $("input#disbursement_revision_tugs_out").on("change", cleanCompute);
  $("input#disbursement_revision_loadtime").on("change", cleanCompute);
  $("input#disbursement_revision_days_alongside").on("change", cleanCompute);
  $("input#disbursement_revision_tax_exempt").on('change', handleTaxExempt);
  $("select#disbursement_revision_cargo_type_id").on('change', function() {
      var ctId = $("select#disbursement_revision_cargo_type_id").val();
      var cargoType = pfda.cargoTypes[ctId];
      if (cargoType) {
        ctx.cargo_type.type = cargoType.maintype;
        ctx.cargo_type.subtype = cargoType.subtype;
        ctx.cargo_type.subsubtype = cargoType.subsubtype;
        ctx.cargo_type.subsubsubtype = cargoType.subsubsubtype;
      }
      update();
  });
  $("a#add_item").on("click", function(e) {
      var item = $("input#extra_item").val();
      if (item) {
        var key = 'EXTRAITEM'+uuid();
        var taxApplies = $("input#extra_tax_applies").is(":checked");
        var index = ctx.services.length;
        ctx.services[index] = key;
        ctx.codes[key] = '{compute: function(ctx) {return 0;},'+
                         'taxApplies: '+taxApplies+'}';
        ctx.values[key] = 0;
        ctx.descriptions[key] = item;
        ctx.compulsory[key] = false;
        ctx.computed[key] = "0";
        ctx.overriden[key] = "0";
        rebuildTable(ctx);
        $("input#extra_item").val('');
      }
  });
  $("select.date").on("change", update);
  $("input#eta_picker").datepicker({
    dateFormat: "dd M yy",
    altField: "input#disbursement_revision_eta",
    altFormat: "yy-mm-dd"
  });
  $('input#extra_item').keypress(function(event) { return event.keyCode != 13; });
  $("input#eta_picker").datepicker(
    "setDate", new Date($("input#disbursement_revision_eta").val()));
  handleTaxExempt();
};
