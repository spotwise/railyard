
import * as bootstrap from 'bootstrap'
import "../stylesheets/application"

require("@fortawesome/fontawesome-free");

document.addEventListener("DOMContentLoaded", function(event) {
  var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
  })

  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })
});

window.setTimeout(function() {
    $(".alert-success").fadeTo(1000, 0).slideUp(500, function(){
        $(this).remove();
    });
}, 5000);
