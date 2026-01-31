/*
 * M2 Desktop - Guacamole Display Fixes
 * Forces 100% zoom and fixes display issues
 */

(function() {
    'use strict';

    // Wait for DOM and Guacamole to be ready
    function initDisplayFixes() {
        // Try to find and fix the display
        var attempts = 0;
        var maxAttempts = 100;

        var fixInterval = setInterval(function() {
            attempts++;

            // Look for the Guacamole display
            var display = document.querySelector('.guac-display');
            var client = null;

            // Try to access the Guacamole client through various paths
            if (window.GuacUI && GuacUI.Client) {
                client = GuacUI.Client;
            } else if (window.Guacamole && Guacamole.Client) {
                // Look for client instance
                var clientElements = document.querySelectorAll('[data-client-id]');
                if (clientElements.length > 0) {
                    client = clientElements[0].__guacClient;
                }
            }

            // If we found a display element, apply CSS fixes
            if (display) {
                // Hide any duplicate canvases (pixel buffer issue)
                var canvases = display.querySelectorAll('canvas');
                if (canvases.length > 1) {
                    for (var i = 1; i < canvases.length; i++) {
                        canvases[i].style.display = 'none';
                    }
                }

                // Constrain display size
                display.style.overflow = 'hidden';
                display.style.maxHeight = '100vh';
                display.style.maxWidth = '100vw';
            }

            // Try to set scale to 100% (1.0)
            if (client && client.display) {
                try {
                    // Disable auto-fit first
                    if (typeof client.display.autoFit !== 'undefined') {
                        client.display.autoFit = false;
                    }

                    // Set scale to 1.0 (100%)
                    if (typeof client.display.scale === 'function') {
                        client.display.scale(1.0);
                        console.log('M2 Desktop: Display scale set to 100%');
                        clearInterval(fixInterval);
                        return;
                    }
                } catch (e) {
                    console.warn('M2 Desktop: Could not set display scale', e);
                }
            }

            // Also try the Angular/modern Guacamole approach
            try {
                var scaleInput = document.querySelector('input[type="range"][max="3"]');
                if (scaleInput) {
                    scaleInput.value = 1;
                    scaleInput.dispatchEvent(new Event('input', { bubbles: true }));
                    scaleInput.dispatchEvent(new Event('change', { bubbles: true }));
                    console.log('M2 Desktop: Scale slider set to 100%');
                }
            } catch (e) {
                // Ignore errors
            }

            // Stop after max attempts
            if (attempts >= maxAttempts) {
                console.log('M2 Desktop: Display fix attempts exhausted');
                clearInterval(fixInterval);
            }
        }, 200);
    }

    // Run fixes when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initDisplayFixes);
    } else {
        initDisplayFixes();
    }

    // Also run on hash change (navigation within Guacamole)
    window.addEventListener('hashchange', function() {
        setTimeout(initDisplayFixes, 500);
    });

})();
