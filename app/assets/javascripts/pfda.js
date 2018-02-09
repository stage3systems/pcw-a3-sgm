$.fn.editable.defaults.mode = 'inline';

var requiredInputDataKey = function(serviceKey, key, serviceSpecific) {
  var dataKey = 'required_input_';
  if (serviceSpecific) {
    dataKey += serviceKey + '_';
  }
  return dataKey + key;
}

var buildInput = function($requiredInputs, serviceKey, val, key, ctx) {
  var dataKey = requiredInputDataKey(serviceKey, key, val.serviceSpecific);
  var value = ctx.data[dataKey] || val.defaultValue;
  $requiredInputs.append(
    '<div class="form-group">'+
    '<label class="control-label col-sm-3">'+val.label+'</label>'+
    '<div class="col-sm-9">'+
    '<input name="'+dataKey+'" class="form-control" value="'+value+'"></input>'+
    '<span class="help-block"></span>'+
    '</div></div>');
};

var buildSelect = function($requiredInputs, serviceKey, val, key, ctx) {
  var dataKey = requiredInputDataKey(serviceKey, key, val.serviceSpecific);
  var value = ctx.data[dataKey] || val.defaultValue;
  var options = _.map(val.options, function(o) {
    return '<option value="'+o.value+'"'+
            (o.value == value ? ' selected="selected"' : '')+'>'+
            o.label+'</option>';
  }).join('');
  $requiredInputs.append(
    '<div class="form-group">'+
    '<label class="control-label col-sm-3">'+val.label+'</label>'+
    '<div class="col-sm-9">'+
    '<select name="'+dataKey+'" class="form-control">'+
    options+
    '</select>'+
    '<span class="help-block"></span>'+
    '</div></div>');
};

var addRequiredFields = function($elem, ctx, s) {
  var requiredInputs = ctx.parsed_codes[s] && ctx.parsed_codes[s].requiredInputs;
  if (requiredInputs) {
    if (_.keys(requiredInputs).length > 0) {
      $elem.append('<hr />');
    }
    return _.map(requiredInputs, function(val, key) {
      if (val.options) {
        buildSelect($elem, s, val, key, ctx);
      } else {
        buildInput($elem, s, val, key, ctx);
      }
    });
  }
};

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
    $tr.append(supplierCell(ctx, s));
    $tr.append(amountCell(ctx, s));
    $tr.append(taxAmountCell(ctx, s));
    $tr.append(disableCell(ctx, s));
    $tbody.append($tr);
  });
  setTimeout(function() {
    displayTaxExempt();
    updateTable(ctx);
    setupRequiredFieldsListeners(ctx);
    setupDisableListeners(ctx);
    setupSortable();
    computeOrder();
  }, 0);
};

var setupRequiredFieldsListeners = function(ctx) {
  _.each(ctx.services, function(s) {
    var requiredInputs = ctx.parsed_codes[s].requiredInputs;
    return _.map(requiredInputs, function(val, key) {
      var dataKey = requiredInputDataKey(s, key, val.serviceSpecific);
      if (val.options) {
        var $select = $('select[name="'+dataKey+'"]');
        var $div = $select.parent().parent();
        var $span = $select.next();
        $select.on('change', function(e) {
          var raw = $(e.target).val();
          var validation = val.validate(raw);
          if (validation.error) {
            $div.addClass('has-error');
            $span.text(validation.error);
          } else {
            $div.removeClass('has-error');
            $span.text('');
            ctx.data[dataKey] = validation.success;
            setTimeout(function() { updateTable(ctx); }, 0);
          }
        });
      } else {
        var $input = $('input[name="'+dataKey+'"]');
        var $div = $input.parent().parent();
        var $span = $input.next();
        $input.on('change', function(e) {
          var raw = $(e.target).val();
          var validation = val.validate(raw);
          if (validation.error) {
            $div.addClass('has-error');
            $span.text(validation.error);
          } else {
            $div.removeClass('has-error');
            $span.text('');
            ctx.data[dataKey] = validation.success;
            setTimeout(function() { updateTable(ctx); }, 0);
          }
        });
      }
    });

  });
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
      var requiredInputs = ctx.parsed_codes[key].requiredInputs;
      _.each(requiredInputs, function(val, riKey) {
        var dataKey = requiredInputDataKey(key, riKey, val.serviceSpecific);
        var value = ctx.data[dataKey];
        var elem = val.options ? 'select' : 'input';
        $(elem+'[name="'+dataKey+'"]').val(value);
      });

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
    $("td a.editable_value").editable({display: valueDisplay, defaultValue: 0})
      .on('shown', function (e, editable) {
        setTimeout(function () {
          editable.input.$input.select();
        }, 0);
      });
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
  var agencyFeesByDesc = _.reduce(agencyFeeKeys, function(acc, k) {
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

var isNamedService = function(s) {
  return s.indexOf('NAMED-SERVICE') === 0;
};

function supplierCell(ctx, s) {
  var $td = $('<td></td>'), $span = $('<span></span>');
  var supplierText = ctx['supplier_name'][s] || '';
  $span.text(supplierText)
  return $td.append($span);
}

var nameCell = function(ctx, s) {
  var $th = $('<th></th>');
  var $descriptionSpan = $('<span class="description">'+
                           ctx.descriptions[s]+'</span>');
  $th.append($descriptionSpan);
  if (isExtraItem(s) || isNamedService(s)) {
    $th.append('&nbsp;');
    var checked = '';
    var m = ctx.codes[s].match(/taxApplies: *(.*)}/);
    if (m && m[1] === 'true') checked = ' checked="checked"';
    $th.append('<small>(<label>Tax Applies: </label>'+
               '<input onchange="toggleTaxApplies(\''+s+'\')" '+
               'id="tax_applies_'+s+'" type="checkbox"'+
               checked+'>)</small>');
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
  addRequiredFields($th, ctx, s);
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
  } else if (isNamedService(s)) {
    $span.addClass('label-success');
    $span.text('Named Extra Item');
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
  var $code = $('<input type="hidden" name="code_'+s+'">');
  $code.val(ctx.codes[s]);
  $td.append($code);
  $td.append('<input type="hidden" name="value_'+s+'">');
  $td.append('<input type="hidden" name="order_'+s+'">');
  $td.append('<input type="hidden" name="value_with_tax_'+s+'">');
  if (isExtraItem(s) || isNamedService(s)) {
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

  window.toggleTaxApplies = function(key) {
    var c = ctx.codes[key];
    var m = c.match(/taxApplies: *(.*)}/);
    if (m && m[1] === 'true') {
      ctx.codes[key] = c.replace('true}', 'false}');
    } else {
      ctx.codes[key] = c.replace('false}', 'true}');
    }
    $('input[name="code_'+key+'"]').val(ctx.codes[key]);
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
  $("a#add_named_item").on("click", function() {
    var key = $("select#named_items").val();
    var namedService = _.find(ctx.named_services, function(ns) { return ns.key == key; });
    $("select#named_items").select2('close');
    $("select#named_items").val(null);
    if (namedService) {
      var key = 'NAMED-SERVICE-'+key+'-'+uuid();
      addExtraItem(key, namedService.item, namedService.taxApplies, namedService.compulsory);
    }
  });
  $("select#named_items").on('add-extra-item', function(src, item) {
    $("select#named_items").select2('close');
    $("select#named_items").val(null);
    if (item) {
      var key = 'EXTRAITEM'+uuid();
      var taxApplies = $("input#extra_tax_applies").is(":checked");
      addExtraItem(key, item, taxApplies);
    }
  });
  $("a#add_item").on("click", function() {
    var item = $("input#extra_item").val();
    if (item) {
      var key = 'EXTRAITEM'+uuid();
      var taxApplies = $("input#extra_tax_applies").is(":checked");
      addExtraItem(key, item, taxApplies);
      $("input#extra_item").val('');
    }
  });
  function addExtraItem(key, item, taxApplies, compulsory) {
    var index = ctx.services.length;
    ctx.services[index] = key;
    ctx.codes[key] = '{compute: function(ctx) {return 0;},'+
                     'taxApplies: '+taxApplies+'}';
    ctx.values[key] = 0;
    ctx.descriptions[key] = item;
    ctx.compulsory[key] = !!compulsory;
    ctx.computed[key] = "0";
    ctx.overriden[key] = "0";
    rebuildTable(ctx);
  }
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
