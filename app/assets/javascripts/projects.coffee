# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

state = ""

changeState = (id, project_id, state) ->
    $.post '/bugs/change_state',
        id: id
        project_id: project_id
        state: state

$(document).on "turbolinks:load", ->
     $(".sortable").sortable
         revert: "100"
         placeholder: 'drag-place-holder'
         forcePlaceholderSize: true 
         connectWith: ".sortable"
         helper: (event, element) -> 
            return $(element).clone().addClass('dragging')
         start: (e, ui) ->
            ui.item.show().addClass('ghost')
            state = ui.item.parent().attr("state")
         stop: (e, ui) ->
            ui.item.show().removeClass('ghost')
            if state isnt ui.item.parent().attr("state")
                changeState(ui.item.attr("id"), ui.item.attr("project_id"), ui.item.parent().attr("state"))
         cursor:'move'
    .disableSelection
    $(".bug").click ->
        window.location = "/projects/#{$(this).attr('project_id')}/bugs/#{$(this).attr('id')}"