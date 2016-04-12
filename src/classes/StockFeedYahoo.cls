/**
 * Provides getHTML implementations for the content templates "StockFeedYahooFavorites" and
 * "StockFeedYahooUserPreferences" as well as attribute accessors for the StockFeedYahoo content editor.
 */
global virtual with sharing class StockFeedYahoo extends cms.ContentTemplateController {
    public String getFavoriteStocksHTML() {
        String serializedDefaultSymbols = JSON.serialize(defaultStockSymbols);

        String html = '';

        html += '<div class="stockSymbolContainer" '
                + 'data-favoritesymbols '
                + 'data-defaultsymbols="' + serializedDefaultSymbols.escapeHtml4() + '">'
            + '</div>';

        return html;
    }

    public String getUserPreferencesHTML() {
        String serializedDefaultSymbols = JSON.serialize(defaultStockSymbols);

        String html = '';

        html += '<div class="stockSymbolPicker" data-stockuserpreferences data-maxsymbols="' + maxFavoriteSymbols + '" '
                    + 'data-defaultsymbols="' + serializedDefaultSymbols.escapeHtml4() + '">'
                + '<div class="stockControls">'
                    + '<div class="panel">'
                        + '<div class="panel-body">'
                            + '<button class="saveSymbols btn btn-default" disabled>Save</button> '
                            + '<span class="selectStocksMessage text-info" style="display:none">'
                                + selectStocksMessage.escapeHtml4()
                            + '</span><span class="tooManyStocksMessage text-warning" style="display:none">'
                                + tooManyStocksMessage.escapeHtml4()
                            + '</span>'
                        + '</div>'
                    + '</div>'
                + '</div>'
                + '<ul class="list-group">'; // Hide these on initial render

        for(Symbol s : symbols) {
            html += '<li class="checkbox list-group-item">'
                        + '<label>'
                            + '<input class="stockSymbolOption" type="checkbox" disabled '
                                + 'value="' + s.symbol.escapeHtml4() + '" />'
                            + '<span> '
                                + s.label.escapeHtml4()
                            + '</span>'
                        + '</label>'
                    + '</li>';
        }

        html += '</ul>'
            + '</div>';

        return html;
    }

    /** Represents one saved symbol, including its label, symbol and whether it should appear as a default symbol. */
    public class Symbol {
        public String label;
        public String symbol;
        public Boolean isDefault;
    }

    /** The list of author-saved symbols. Used by "StockFeedYahooFavorites" and "StockFeedUserPreferences" */
    public List<Symbol> symbols {
        get {
            if(symbols == null) {
                symbols = new List<Symbol>();

                Integer symbolCount;

                try {
                    symbolCount = Integer.valueOf(getAttribute('symbolCount'));
                } catch(Exception e) {}

                if(symbolCount != null && symbolCount > 0) {
                    for(Integer i = 0; i < symbolCount; ++i) {
                        Symbol s = new Symbol();
                        s.label = getAttribute('symbolLabel' + i);
                        s.symbol = getAttribute('symbol' + i);
                        s.isDefault = getAttribute('symbolIsDefault' + i) == 'true';

                        if(s.label == null) s.label = '';
                        if(s.symbol == null) s.symbol = '';

                        symbols.add(s);
                    }
                }
            }

            return symbols;
        } set;
    }

    /** A JSON-serialized form of {@link #symbols}. Used by the edit page. */
    public String symbolsJson {
        get {
            return JSON.serialize(symbols);
        } set;
    }

    /**
     * The list of symbols with the isDefault flag set to true. Used by "StockFeedYahooFavorites" and
     * "StockFeedUserPreferences"
     */
    public List<String> defaultStockSymbols {
        get {
            if(defaultStockSymbols == null) {
                defaultStockSymbols = new List<String>();
                for(Symbol s : symbols) {
                    if(s.isDefault) {
                        defaultStockSymbols.add(s.symbol);
                    }
                }
            }

            return defaultStockSymbols;
        } set;
    }

    /**
     * The maximum number of favourite symbols a user may select. Defaults to 3 and must be between 1 and 5 inclusive.
     * Used by "StockFeedYahooUserPreferences".
     */
    public Integer maxFavoriteSymbols {
        get {
            if(maxFavoriteSymbols == null) {
                // Default to 3
                maxFavoriteSymbols = 3;

                try {
                    maxFavoriteSymbols = Integer.valueOf(getAttribute('maxFavoriteSymbols'));
                } catch(Exception e) {}

                // Always return an integer between 1 and 5 inclusive, defaulting to 3
                if(maxFavoriteSymbols == null) {
                    maxFavoriteSymbols = 3;
                } else if(maxFavoriteSymbols < 1) {
                    maxFavoriteSymbols = 1;
                } else if(maxFavoriteSymbols > 5) {
                    maxFavoriteSymbols = 5;
                }
            }

            return maxFavoriteSymbols;
        } set;
    }

    /**
     * The message displayed to a user prompting them to select their favourite stocks. Used by
     * "StockFeedYahooUserPreferences"
     */
    public String selectStocksMessage {
        get {
            if(selectStocksMessage == null) {
                selectStocksMessage = getAttribute('selectStocksMessage');

                if(selectStocksMessage == null) {
                    selectStocksMessage = 'Select stock symbols as your favourites.';
                }
            }

            return selectStocksMessage;
        } set;
    }

    /**
     * The message displayed to a user they have selected too many favourite stocks. Used by
     * "StockFeedYahooUserPreferences"
     */
    public String tooManyStocksMessage {
        get {
            if(tooManyStocksMessage == null) {
                tooManyStocksMessage = getAttribute('tooManyStocksMessage');

                if(tooManyStocksMessage == null) {
                    tooManyStocksMessage = 'To save changes, you must select fewer stock symbols.';
                }
            }

            return tooManyStocksMessage;
        } set;
    }

    /** Provides an easy way to define attributes during testing */
    @TestVisible
    private Map<String, String> testAttributes = new Map<String, String>();

    /** Delegates to ContentTemplateController#getProperty in normal execution. Accesses the {@link #testAttributes}
     * map in a test context.
     */
    private String getAttribute(String attributeName) {
        if(Test.isRunningTest()) {
            return testAttributes.get(attributeName);
        } else {
            return getProperty(attributeName);
        }
    }

    /** Extension constructor for the Article edit page */
    global StockFeedYahoo(cms.CreateContentController cc) {
        super(cc);
    }

    /** Extension constructor for Article generate pages (unused) */
    private StockFeedYahoo(cms.GenerateContent gc) {
        super(gc);
    }

    /** Constructor for getHTML rendering */
    global StockFeedYahoo() {
        super();
    }

    /** Blank getHTML - rendering is done by subclasses */
    global virtual override String getHTML() {
        return '';
    }
}
