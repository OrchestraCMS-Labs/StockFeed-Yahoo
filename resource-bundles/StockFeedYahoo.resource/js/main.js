window.STG = window.STG || {};
window.STG.CTLib = window.STG.CTLib || {};

window.STG.CTLib.StockFeedYahoo = (function(global, namespace, undefined) {
    'use strict';

    var serviceName = 'StockFeedYahooService';

    var favoriteStocksContainerSelector = '[data-favoritesymbols]';

    var symbolPickerContainerSelector = '[data-stockuserpreferences]';
    var symbolCheckboxSelector = '.stockSymbolOption';

    /* By default, initialize all favorite stock widgets and symbol pickers on document ready */
    $(function() {
        $(favoriteStocksContainerSelector).each(function() {
            namespace.initFavoriteQuotesWidget($(this));
        });

        $(symbolPickerContainerSelector).each(function() {
            namespace.initSymbolPicker($(this));
        });
    });

    /**
     * Initializes a favorite quotes widget for a given container element.
     *
     * <p>Examines the provided container element for a set of default symbols in the data-defaultsymbols attribute,
     * calls out to getUserQuotes to fetch the appropriate quote data, then renders the quotes.</p>
     *
     * <p>Data attributes that should appear on the container element are:
     * <ul>
     *   <li>data-defaultsymbols - a JSON-serialized array of the default symbols to use if the user has no preferences
     * saved</li>
     * </ul>
     *
     * @param $container a jQuery collection containing the parent element
     */
    namespace.initFavoriteQuotesWidget = function($container) {
        var isContainerInitialized = $container.attr('data-initialized') !== undefined;
        var defaultSymbols = [];
        var defaultSymbolsAttribute = $container.attr('data-defaultsymbols');

        // Were default symbols provided?
        if(typeof defaultSymbolsAttribute !== typeof undefined && defaultSymbolsAttribute !== false) {
            defaultSymbols = JSON.parse(defaultSymbolsAttribute);
        }

        function fetchAndRenderQuotes() {
            // Fetch and render quotes
            namespace.getUserQuotes(defaultSymbols, function(alwaysTrue, result) {
                if(!result.success) {
                    console.error(result.message);
                } else {
                    namespace.renderQuotes($container, result.quotes);
                }
            });
        }

        if(!isContainerInitialized) {
            $(document).on('stockFeedYahooPreferencesChanged', fetchAndRenderQuotes);
            fetchAndRenderQuotes();
        }
    };

    /**
     * Initializes a stock symbol picker widget for a given container element.
     *
     * <p>Examines the provided container element for a set of default symbols in the data-defaultsymbols attribute,
     * calls out to getUserQuotesPreferences to fetch the user's current saved preferences (if they exist) then
     * initializes the controls.</p>
     *
     * <p>Data attributes that should appear on the container element are:
     * <ul>
     *   <li>data-maxsymbols - the maximum number of symbols a user can select</li>
     *   <li>data-defaultsymbols - a JSON-serialized array of the default symbols if the user has no preferences
     * saved</li>
     * </ul>
     *
     * @param $container a jQuery collection containing the parent element
     */
    namespace.initSymbolPicker = function($container) {
        var isContainerInitialized = $container.attr('data-initialized') !== undefined;
        var maxSelectableSymbols = $container.attr('data-maxsymbols');
        var $saveButton = $('.saveSymbols', $container);
        var $tooManyStocksMessage = $('.tooManyStocksMessage', $container);
        var $selectStocksMessage = $('.selectStocksMessage', $container);

        var defaultSymbols = [];
        var defaultSymbolsAttribute = $container.attr('data-defaultsymbols');

        // Were default symbols provided?
        if(typeof defaultSymbolsAttribute !== typeof undefined && defaultSymbolsAttribute !== false) {
            defaultSymbols = JSON.parse(defaultSymbolsAttribute);
        }

        // Show the appropriate message prompt depending on whether the user has checked more than the allowable
        // number of symbols
        function showMessagePrompt() {
            var selectedStocksCount = $(symbolCheckboxSelector + ':checked', $container).length;
            var hasTooManyStocksSelected = selectedStocksCount > maxSelectableSymbols;

            if(hasTooManyStocksSelected) {
                $saveButton.prop('disabled', true);
                $tooManyStocksMessage.show();
                $selectStocksMessage.hide();
            } else {
                $saveButton.prop('disabled', false);
                $tooManyStocksMessage.hide();
                $selectStocksMessage.show();
            }
        }

        // Fetch the user's saved preferences and render the UI
        namespace.getUserQuotesPreferences(function(alwaysTrue, result) {
            if(!result.success) {
                console.error(result.message);
            } else {
                if(result.preferences === null) {
                    namespace.renderSymbolPicker($container, defaultSymbols);
                } else {
                    namespace.renderSymbolPicker($container, result.preferences);
                }

                showMessagePrompt();
            }
        });

        // Only attach events if the container hasn't been initialized yet
        if(!isContainerInitialized) {
            // When a checkbox changes, check if the user has too many checkboxes selected
            $container.on('change', symbolCheckboxSelector, function _handleSymbolCheckboxChange(evt) {
                showMessagePrompt();
            });

            // Save the user's preferences when they click the save button
            $saveButton.click(function _handleSaveButtonClick(evt) {
                var symbols = [];

                $(symbolCheckboxSelector + ':checked', $container).each(function() {
                    symbols.push(this.value);
                });

                $saveButton.prop('disabled', true);

                namespace.postUserQuotesPreferences(symbols, function _callback(alwaysTrue, result) {
                    $saveButton.prop('disabled', false);
                    $(document).trigger('stockFeedYahooPreferencesChanged');
                });
            });

            // Mark this container as initialized
            $container.attr('data-initialized', 'true');
        }
    };

    /**
     * Renders a set of stock quotes suitable for display on a toolbar.
     *
     * <p>This will destroy any current children of $container.</p>
     *
     * <p>Example markup for a single quote:</p>
     *
     * <pre>
     * {@code
     * <a href="https://finance.yahoo.com/q?s={symbol}" target="_blank"
     *         class="stockSymbol label label-default" title="Open Yahoo stock information in a new window">
     *     <span>{symbol} </span>
     *     <span class="glyphicon {glyphicon-chevron-down|glyphicon-chevron-up|glyphicon glyphicon-minus"></span>
     *     <span> {quote}</span>
     * </a>
     * }
     *
     * @see getUserQuotes for an example. Refer to responseObject.quotes
     *
     * @param $container a jQuery collection containing the parent element
     * @param quotes a JavaScript object containing the quote data.
     */
    namespace.renderQuotes = function($container, quotes) {
        $container.empty();

        for(var key in quotes) {
            (function _renderSingleQuote() { // IIFE
                var quote = quotes[key];
                var urlEncodedSymbol = encodeURIComponent(quote.symbol);
                var changeClass;
                var $containingAnchor;

                // These classes reference Bootstrap v3's glypicon font
                if(quote.percentChange < 0) {
                    changeClass = 'glyphicon glyphicon-chevron-down';
                } else if(quote.percentChange > 0) {
                    changeClass = 'glyphicon glyphicon-chevron-up';
                } else {
                    changeClass = 'glyphicon glyphicon-minus';
                }

                // Create the container for this quote
                $containingAnchor = $('<a />')
                    .prop({
                        href: 'https://finance.yahoo.com/q?s=' + urlEncodedSymbol,
                        target: '_blank',
                        'class': 'stockSymbol label label-default',
                        title: 'Open Yahoo stock information in a new window'
                    });

                // Populate the anchor with the symbol, arrow icon and current quote
                $containingAnchor.append(
                    $('<span class="symbol-symbol" />').text(quote.symbol + ' '),
                    $('<span class="symbol-arrow" />').addClass(changeClass),
                    $('<span class="symbol-quote" />').text(' ' + quote.quote)
                );

                $container.append($containingAnchor, ' ');
            }());
        }
    };

    /**
     * Completes the rendering of a stock symbol picker.
     *
     * <p>This assumes that the markup has been generated by the content's getHTML method and simply .</p>
     *
     * <p>Example markup for a single quote:</p>
     *
     * <pre>
     * {@code
     * <a href="https://finance.yahoo.com/q?s={symbol}" target="_blank"
     *         class="stockSymbol label label-default" title="Open Yahoo stock information in a new window">
     *     <span>{symbol} </span>
     *     <span class="glyphicon {glyphicon-chevron-down|glyphicon-chevron-up|glyphicon glyphicon-minus"></span>
     *     <span> {quote}</span>
     * </a>
     * }
     *
     * @see getUserQuotes for an example. Refer to responseObject.quotes
     *
     * @param $container a jQuery collection containing the parent element
     * @param quotes a JavaScript object containing the quote data.
     */
    namespace.renderSymbolPicker = function($container, selectedSymbols) {
        // The markup exists - we check the selected boxes
        if(!Array.isArray(selectedSymbols)) {
            selectedSymbols = [];
        }

        $('.stockSymbolOption', $container).each(function() {
            var $checkbox = $(this);

            if(selectedSymbols.indexOf($checkbox.val()) !== -1) {
                $checkbox.prop({
                    checked: true,
                    disabled: false
                });
            } else {
                $checkbox.prop({
                    checked: false,
                    disabled: false
                });
            }
        });
    };

    /**
     * Calls the service action getUserQuotes with the provided defaults and passes the server result to the
     * specified callback function as the second argument.
     *
     * <p>On success a response object will have the form:</p>
     *
     * <pre>
     * {@code
     * {
     *     success: true,
     *     quotes: {
     *         'symbol1': {
     *             symbol: 'symbol1',
     *             quote: _number_,
     *             percentChange: _number_,
     *             change: _number_
     *         },
     *         'symbol2': {
     *             symbol: 'symbol2',
     *             quote: _number_,
     *             percentChange: _number_,
     *             change: _number_
     *         }
     *     }
     * }
     * }
     * </pre>
     *
     * @param defaults a JavaScript array containing the default symbols to look up if the user has no preferences
     * @param callback a JavaScript function that takes the result object as its second argument
     */
    namespace.getUserQuotes = function(defaults, callback) {
        if(!Array.isArray(defaults)) {
            defaults = [];
        }

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, {
            action: 'getUserQuotes',
            defaults: JSON.stringify(defaults)
        }, callback, null, true); // Read-only mode
    };

    /**
     * Calls the service action getQuotes with the provided symbols and passes the server result to the specified
     * callback function as the second argument.
     *
     * @see getUserQuotes for the response object format
     *
     * @param symbols a JavaScript array containing the symbols to look up
     * @param callback a JavaScript function that takes the result object as its second argument
     */
    namespace.getQuotes = function(symbols, callback) {
        if(!Array.isArray(symbols)) {
            symbols = [];
        }

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, {
            action: 'getQuotes',
            symbols: JSON.stringify(symbols)
        }, callback, null, true); // Read-only mode
    };

    /**
     * Calls the service action getUserQuotesPreferences and passes the server result to the specified callback
     * function as the second argument.
     *
     * <p>If a use has saved preferences a response object will have the form:</p>
     *
     * <pre>
     * {@code
     * {
     *     success: true,
     *     preferences: [
     *         'symbol1',
     *         'symbol2',
     *         ...
     *     ]
     * }
     * }
     * </pre>
     *
     * <p>If a user does not have saved preferences the response object will be:</p>
     * <pre>
     * {@code
     * {
     *     success: true,
     *     preferences: null
     * }
     * }
     * </pre>
     *
     * @param callback a JavaScript function that takes the result object as its second argument
     */
    namespace.getUserQuotesPreferences = function(callback) {
        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, {
            action: 'getUserQuotesPreferences'
        }, callback, null, true); // Read-only mode
    }

    /**
     * Calls the service action postUserQuotesPreferences with the provided preferences and passes the server result
     * to the specified callback function as the second argument.
     *
     * <p>On success a response object will have the form:</p>
     *
     * <pre>
     * {@code
     * {
     *     success: true
     * }
     * }
     *
     * @param preferences a JavaScript array containing the user's preferred symbols
     * @param callback a JavaScript function that takes the result object as its second argument
     */
    namespace.postUserQuotesPreferences = function(preferences, callback) {
        if(!Array.isArray(preferences)) {
            preferences = [];
        }

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, {
            action: 'postUserQuotesPreferences',
            preferences: JSON.stringify(preferences)
        }, callback);
    };

    return namespace;
}(window, STG.CTLib.StockFeedYahoo || {}));
