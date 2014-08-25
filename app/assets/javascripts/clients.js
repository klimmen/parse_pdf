

var spinner
var target
var status_container
var token

var n
$(function() {
    token = $('meta[name="csrf-token"]').attr('content');
 // alert(token)

});
$(document).on("page:change",function(){ 
if (window.location.pathname.match(/clients/) == 'clients')
{
try {
  n = gon.global.jid.length
} catch(e) {

}



 if (n > 1 && gon.global.user[n-1] == token) {
  //console.log("+")
  for (var key = 1; key < n; key++) {
  //  console.log(gon.global.user)
  //  console.log(token)
    if (gon.global.user[key] == token)
    {
      document.getElementById('spinnerContainer').innerHTML += 'Parse launch file: '+gon.global.name_pdf_file[key]+ ' <br>';
    }
  }
  document.getElementById("spinnerContainer").style.padding="15px 35px 15px 14px";
  document.getElementById("spinnerContainer").style.marginTop="20px";
  displayDate();
//  console.log("displayDate")
  SetDelay ();
  $(function () {
    $('.gon_watch_stop').click(function (event) {
      clearTimeout (delayTime);         
    })
  });
}
}
})
function displayDate(){    
  var opts = {
    lines: 13, // The number of lines to draw
    length: 7, // The length of each line
    width: 4, // The line thickness
    radius: 10, // The radius of the inner circle
    corners: 1, // Corner roundness (0..1)
    rotate: 0, // The rotation offset
    color: '#000', // #rgb or #rrggbb
    speed: 1, // Rounds per second
    trail: 60, // Afterglow percentage
    shadow: false, // Whether to render a shadow
    hwaccel: false, // Whether to use hardware acceleration
    className: 'spinner', // The CSS class to assign to the spinner
    zIndex: 2e9, // The z-index (defaults to 2000000000)
    top: 'auto', // Top position relative to parent in px
    left: 'auto' // Left position relative to parent in px      
  };
  target = document.getElementById('spinnerContainer');
  spinner = new Spinner(opts).spin(target);    
}
  
function SetDelay () {
  delayTime = setTimeout ("Counter ()",3000);
}
function Counter () {
  for (var key = n-1; key > 0; key--) {
 //   console.log('gon.global.jid.length = '+n)
 //   console.log(gon.global.jid)
 //   console.log(key)
    $.ajax({
      url: "/qwerty",
      type: "POST",
      data: {key: key},
      success: function(data){
        status_container = data.status_sidekiq  
  //      console.log("jid = "+gon.global.jid[data.keyy]+ ", key = "+ data.keyy+", status = "+status_container)}, 
        }               
    });
    if (status_container == 'complete') {
      n=n-1
      document.getElementById('spinnerContainer').innerHTML =''
      for (var i = (gon.global.jid.length-n); i < gon.global.jid.length; i++) {
        if (gon.global.user[key] == token)
        {
          document.getElementById('spinnerContainer').innerHTML += 'Parse launch file: '+gon.global.name_pdf_file[i]+ ' <br>';
        }
      } 
    }
    if (n==1){
      spinner.stop(target);
      document.getElementById('spinnerContainer').innerHTML = '' ;
      document.getElementById("spinnerContainer").style.padding="0px 0px 0px 0px"; 
      document.getElementById("spinnerContainer").style.marginTop="0px";     
      //alert('File is succesfully loaded');
      window.location.reload();
      clearTimeout (delayTime);
    }
  }
  SetDelay ();

}






