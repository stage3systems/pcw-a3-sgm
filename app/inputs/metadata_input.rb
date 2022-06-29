class MetadataInput < SimpleForm::Inputs::Base
  def input(wrapper_options = nil)
    template.content_tag(:div) do
      """
      <div>
        <table class='table table-striped table-bordered metadata-list'>
          <thead>
            <tr>
              <th>Key</th>
              <th>Value</th>
              <th></th>
            <tr>
          </thead>
          <tbody class='data'>
          </tbody>
          <tfoot>
            <tr>
              <td><input class=\"form-control\" id=\"metadata_key\" placeholder=\"key\" /></td>
              <td><input class=\"form-control\" id=\"metadata_value\" placeholder=\"value\" /></td>
              <td><button type=\"button\" class=\"btn btn-sm btn-success add\">Add</button></td>
            </tr>
          </tfoo>
        </table>
      </div>
      <script type='text/javascript'>
        var data = #{(object.send(attribute_name) || {}).to_json};
        var rebuild = function() {
          $('tbody').empty();
          _.each(data, function(v, k) {
            $('tbody.data').append(
              '<tr>'+
              '<td>'+k+'</td>'+
              '<td>'+v+'</td>'+
              '<td><button type=\"button\" class=\"btn btn-xs btn-warning delete\" id=\"'+k+'\">Delete</td>'+
              '<input type=\"hidden\" name=\"#{options[:entity]}[metadata]['+k+']\" id=\"#{options[:entity]}_metadata_'+k+'\" value=\"'+v+'\"></input>'+
              '</tr>');
          });
          $('button.delete').on('click', function() {
            delete data[$(this).attr('id')];
            setTimeout(rebuild, 0);
          });
        }
        $('button.add').on('click', function() {
          var key = $('input#metadata_key').val();
          var val = $('input#metadata_value').val();
          if (key != '' && val != '') {
            data[key] = val;
            $('input#metadata_key').val('');
            $('input#metadata_value').val('');
            rebuild();
          }
          console.log('add');
        });
        rebuild();
      </script>
      """.html_safe
      #template.input_tag :metadata, type: 'hidden'
    end
  end
end
