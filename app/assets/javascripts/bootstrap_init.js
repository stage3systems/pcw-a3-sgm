var refreshOddEven = function() {
  $('tbody tr').removeClass('odd');
  $('tbody tr').removeClass('even');
  $('tbody tr').each(function(i, e) {
    var cls = (i & 1) === 0 ? 'odd' : 'even';
    $(e).addClass(cls);
  });
};
var copyAce;
var ready = function() {
  var aces = $('*[data-ace-editor-target]');
  aces.each(function() {
    var div = $(this);
    div.parent().css('width', "600px").css('height', '400px').css("position", "relative");
    div.css("position", "absolute").css('left', "0px").css('right', "0px").css('top', "0px").css('bottom', "0px");
    var target = $("#" + div.data('ace-editor-target'));
    target.hide();
    var editor = ace.edit(div.attr('id'));
    editor.setTheme("ace/theme/clouds");
    var mode = require("ace/mode/javascript").Mode;
    editor.getSession().setMode(new mode());
    editor.getSession().setUseSoftTabs(true);
    editor.getSession().setTabSize(2);
    editor.getSession().setValue(target.val());
    editor.session.setOption("useWorker", false);
    $("*[data-ace-insert="+div.data('ace-editor-target')+"]").change(function() {
      editor.insert("{{"+$(this).val()+"}}");
    });

    copyAce = function(){
      var s = editor.getSession().getValue();
      console.log(s);
      target.val(s);
    }
    div.parents("form").submit(copyAce);
  });
  $('#sortable').sortable({
    axis: 'y',
    items: '.item',
    stop: function(e, ui) {
      return ui.item.children('td').effect('highlight', {}, 1000);
    },
    update: function(e, ui) {
      var data, item_id, position;
      item_id = ui.item.data('item_id');
      position = ui.item.index();
      data = {
        id: item_id,
        row_order_position: position
      };
      $.ajax({
        type: 'POST',
        url: $(this).data('update_url'),
        dataType: 'json',
        data: data
      });
      return setTimeout(refreshOddEven, 10);
    }
  });
  $('table.datatable').dataTable({
    sPaginationType: "bootstrap"
  });
};
$(document).ready(ready);
$(document).on('page:load', ready);
$(document).on('page:change', function() {
  if (window._paq) {
    _paq.push(['setDocumentTitle', document.title]);
    _paq.push(['trackPageView']);
  }
});
var getBloodhoundFor = function(entities) {
  var b = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: '/'+entities+'/search/%QUERY.json'
  });
  b.initialize();
  return b;
}
