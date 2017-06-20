# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on "turbolinks:load", ->
    $(".project").click ->
        window.location = "/projects/#{$(this).attr('id')}"
    $(".bug").click ->
        window.location = "/projects/#{$(this).attr('project_id')}/bugs/#{$(this).attr('id')}"