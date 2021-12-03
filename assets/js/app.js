(function() {
  var button = document.getElementById('toggle-nav');
  var nav = document.getElementById('bs-example-navbar-collapse-1');
  button.onclick = function(){nav.classList.toggle('display');};

  var details = document.querySelectorAll("#bs-example-navbar-collapse-1 details");
  details.forEach((detail) => {
    detail.onclick = () => {
      details.forEach((d) => {
        if (d !== detail) {
          d.removeAttribute("open");
        };
      });
    };
  });
})();
