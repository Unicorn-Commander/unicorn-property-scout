// Magic Unicorn Icon Size Fix
(function() {
    function fixIconSizes() {
        // Target all SVG elements
        const svgs = document.querySelectorAll('svg');
        svgs.forEach(svg => {
            // Skip navigation icons (make them slightly larger)
            if (svg.closest('#links_on_top')) {
                svg.style.width = '1.125rem';
                svg.style.height = '1.125rem';
                svg.style.maxWidth = '1.125rem';
                svg.style.maxHeight = '1.125rem';
            } else {
                // All other icons get standard size
                svg.style.width = '1rem';
                svg.style.height = '1rem';
                svg.style.maxWidth = '1rem';
                svg.style.maxHeight = '1rem';
                svg.style.minWidth = '1rem';
                svg.style.minHeight = '1rem';
                svg.style.display = 'inline-block';
                svg.style.verticalAlign = 'middle';
                svg.style.flexShrink = '0';
            }
        });
    }

    // Run on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', fixIconSizes);
    } else {
        fixIconSizes();
    }

    // Also run after a short delay to catch any dynamically loaded content
    setTimeout(fixIconSizes, 100);
})();