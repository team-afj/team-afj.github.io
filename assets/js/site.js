// Vanilla port of the former jQuery theme script.
(function () {
    var header = document.getElementById('header');

    function scrollHeader() {
        if (header) header.classList.toggle('scrolled', window.scrollY > 75);
    }

    function parallaxBackground() {
        var y = (window.scrollY * 0.3) + 'px';
        document.querySelectorAll('.parallax').forEach(function (el) {
            el.style.backgroundPositionY = y;
        });
    }

    scrollHeader();
    window.addEventListener('scroll', function () {
        scrollHeader();
        parallaxBackground();
    }, { passive: true });

    // Smooth scroll to start
    var toStart = document.getElementById('to-start');
    if (toStart) toStart.addEventListener('click', function (e) {
        e.preventDefault();
        var start = document.getElementById('start');
        window.scroll({ top: start.offsetTop - 45, left: 0, behavior: 'smooth' });
    });

    // Smooth scroll to top
    var toTop = document.getElementById('to-top');
    if (toTop) toTop.addEventListener('click', function (e) {
        e.preventDefault();
        window.scroll({ top: 0, left: 0, behavior: 'smooth' });
    });

    // Responsive menu
    var toggle = document.getElementById('toggle');
    if (toggle) toggle.addEventListener('click', function () {
        toggle.classList.toggle('active');
        document.getElementById('overlay').classList.toggle('open');
        document.body.classList.toggle('mobile-nav-open');
    });

    // Lightbox for the galleries
    if (window.GLightbox && document.querySelector('.glightbox')) {
        GLightbox({
            selector: '.glightbox',
            touchNavigation: true,
            keyboardNavigation: true,
            closeOnOutsideClick: true,
            loop: false,
            draggable: true,
            descPosition: 'bottom'
        });
    }
})();
