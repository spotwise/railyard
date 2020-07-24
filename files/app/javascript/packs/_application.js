
window.setTimeout(function() {
    $(".alert-success").fadeTo(1000, 0).slideUp(500, function(){
        $(this).remove();
    });
}, 5000);
