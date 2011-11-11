/*
 * Copyright 2011 Exavideo LLC.
 * 
 * This file is part of videohub_control.
 * 
 * videohub_control is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * videohub_control is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with videohub_control.  If not, see <http://www.gnu.org/licenses/>.
 */

function load_input_selector(data) {
    $.each(data, function(i,x) {
        var option = $("<option />")
            .attr('value', i)
            .text(x.label + '[' + (i+1) + ']');
        $("#selectorBase").append(option);
    });
}

function on_selector_change() {
    var output_id = $(this).data('output');
    var input_id = $(this).val();
    var thiz = $(this);

    $.ajax('/output/' + output_id, {
        type: 'PUT',
        contentType: 'application/json',
        data: JSON.stringify({ 'input' : input_id }),
        success: function() {
            thiz.data('last_input', input_id)
        },
        error: function() {
            alert("Failed to take input " + (input_id+1) + 
                " on output " + (output_id+1));
            // revert back to whatever it was before
            thiz.val(thiz.data('last_input'));
        }
    });
}

function load_outputs_table(data) {
    $.each(data, function(i, x) {
        var row = $("<tr/>");
        var outputName = $("<td />").text(x.label + '[' + (i+1) + ']');
        
        var selector = $("#selectorBase").clone().css('display','');
        selector.val(x.input);
        selector.data('output', i);
        selector.data('last_input', x.input);
        selector.change(on_selector_change);

        var inputSelect = $("<td />").append(selector);
        row.append(outputName);
        row.append(inputSelect);
        $("#controls").append(row);
    });
}


$(document).ready(function() {
    $.get('/inputs', function(data) {
        load_input_selector(data);
        $.get('/outputs', function(data) {
            load_outputs_table(data);
        });
    });
});
