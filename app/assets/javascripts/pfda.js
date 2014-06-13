$.fn.editable.defaults.mode = 'inline';

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
  var valueDisplay = function(value, sourceData) {
    var key = $(this).attr("id").split("_")[1];
    var val = normalizeValue(value);
    if (ctx.computed[key] != val) {
      ctx.overriden[key] = val;
      $('input[name="overriden_'+key+'"]').val(val);
    }
    $(this).html(convert(val));
    setTimeout(update, 0);
  };
  function update() {
    ctx.estimate.eta = new Date($("input#disbursement_revision_eta").val());
    ctx.estimate.cargo_qty = parseInt($("input#disbursement_revision_cargo_qty").val());
    ctx.estimate.tugs_in = parseInt($("input#disbursement_revision_tugs_in").val()),
    ctx.estimate.tugs_out = parseInt($("input#disbursement_revision_tugs_out").val()),
    ctx.estimate.loadtime = parseInt($("input#disbursement_revision_loadtime").val()),
    ctx.estimate.days_alongside = parseFloat($("input#disbursement_revision_days_alongside").val())
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
      if ((key in ctx.overriden) && key.indexOf("EXTRAITEM") != 0) {
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
                      $('input[name="comment_'+key+'"]').val(value);
                      },
          emptytext: 'Click to add Comment'
    });
    $("td a.editable_value").editable({display: valueDisplay});
  }
  var cleanCompute = function() {
    $("a.editable_value").removeClass("editable-unsaved");
    update();
  };

  var handleTaxExempt = function() {
    var taxExempt = $("input#disbursement_revision_tax_exempt").is(':checked');
    if (taxExempt) {
      $(".tax").hide();
    } else {
      $(".tax").show();
    }
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
        ctx.services[pfda.numItems] = key;
        ctx.codes[key] = '{compute: function(ctx) {return 0;},'
                         +'taxApplies: '+taxApplies+'}';
        ctx.values[key] = 0;
        ctx.compulsory[key] = false;
        ctx.computed[key] = "0";
        ctx.overriden[key] = "0";
        $("table.disbursement tbody").append(
            '<tr class="service" id="service_'+key+'">'
             +'<th>'+item+'&nbsp;<i class="glyphicon glyphicon-remove-circle" '
                                  +'onclick="removeExtra(\''+key+'\')"></i>'
                  +'&nbsp;<span class="editable_value" '
                              +'id="comment_'+key+'"></span>'
             +'</th>'
             +'<td id="service_'+key+'">'
               +'<a class="editable_value" id="field_'+key+'" '
                  +'title="Click to override" href="#"></a>&nbsp;'
               +'<i class="hidden glyphicon glyphicon-remove-circle" '
                  +'onclick="revertValue(\''+key+'\')"></i>'
               +'<input type="hidden" name="overriden_'+key+'" />'
               +'<input type="hidden" name="value_'+key+'" />'
               +'<input type="hidden" name="value_with_tax_'+key+'" '
                      +'value="0" />'
              +'<input type="hidden" name="code_'+key+'" '
                     +'value="'+ctx.codes[key]+'" />'
              +'<input type="hidden" name="description_'+key+'" '
                     +'value="'+item+'" />'
               +'<input type="hidden" name="comment_'+key+'" />'
               +'<input  type="hidden" name="disabled_'+key+'" value="0" />'
             +'</td>'
             +'<td id="service_with_tax_'+key+'" class="tax"></td>'
             +'<td><input class="disable" type="checkbox" '
                        +'name="disable_'+key+'" /></td>'
           +'</tr>');
        $("input#extra_item").val("");
        $("input#extra_tax_applies").removeAttr("checked");
        pfda.numItems += 1;
        handleTaxExempt();
        setupDisableListeners();
      }
  });
  var setupDisableListeners = function() {
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
          update();
      });
  };
  setupDisableListeners();
  $("select.date").on("change", update);
  $("input#eta_picker").datepicker({
    dateFormat: "dd M yy",
    altField: "input#disbursement_revision_eta",
    altFormat: "yy-mm-dd"
  })
  $("input#eta_picker").datepicker(
    "setDate", new Date($("input#disbursement_revision_eta").val()));
  $("input#eta_picker").on("change", update);
  handleTaxExempt();
};
