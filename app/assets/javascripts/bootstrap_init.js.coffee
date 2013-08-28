jQuery ->
   refreshOddEven = () ->
      $('tbody tr').removeClass('odd')
      $('tbody tr').removeClass('even')
      $('tbody tr').each (i, e) ->
         cls = if ((i&1) == 0) then 'odd' else 'even'
         $(e).addClass(cls)
   $('#sortable').sortable(
      axis: 'y'
      items: '.item'
      # highlight the row on drop to indicate an update
      stop: (e, ui) ->
         ui.item.children('td').effect('highlight', {}, 1000)
      update: (e, ui) ->
         item_id = ui.item.data('item_id')
         position = ui.item.index()
         data = {
            id: item_id,
            row_order_position: position
         }
         $.ajax(
            type: 'POST'
            url: $(this).data('update_url')
            dataType: 'json'
            data: data
         )
         setTimeout(refreshOddEven, 10)
   )
   $('table.datatable').dataTable(sPaginationType: "bootstrap")
