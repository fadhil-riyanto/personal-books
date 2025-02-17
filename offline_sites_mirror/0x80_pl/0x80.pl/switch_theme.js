document.addEventListener('DOMContentLoaded', function() {
    let body = document.getElementsByTagName("body")[0];

    function set_style() {
        let dark = (window.localStorage.getItem("mode") == "dark");
        body.classList.toggle("dark", dark);
    }

    let button = document.createElement("button");
    button.innerText = "🌓︎";
    body.insertBefore(button, body.firstChild);

    button.addEventListener("click", function() {
        if (window.localStorage.getItem("mode") == "dark") {
            window.localStorage.setItem("mode", "light");
        } else {
            window.localStorage.setItem("mode", "dark");
        }

        set_style();
    });
    
    set_style();
});
