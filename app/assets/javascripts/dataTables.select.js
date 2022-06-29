jQuery.extend( jQuery.fn.dataTableExt.oSort, {
    "select-pre": function ( a ) {
        return $(a).val();
    },

    "select-asc": function ( a, b ) {
        return ((a < b) ? -1 : ((a > b) ? 1 : 0));
    },

    "select-desc": function ( a, b ) {
        return ((a < b) ? 1 : ((a > b) ? -1 : 0));
    }
} );
