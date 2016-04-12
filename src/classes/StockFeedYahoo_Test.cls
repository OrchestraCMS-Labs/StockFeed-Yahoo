@isTest
private with sharing class StockFeedYahoo_Test {
    private static Map<String, String> testAttributesBase = new Map<String, String> {
        'symbolCount' => '2',
        'symbolLabel0' => 'default symbol',
        'symbol0' => 'DEFAULT_SYMBOL',
        'symbolIsDefault0' => 'true',

        'symbolLabel1' => 'not default symbol',
        'symbol1' => 'NOT_DEFAULT_SYMBOL',
        'symbolIsDefault1' => 'false'
    };

    private static testmethod void testGetFavoriteStocksHTML_withDefaults() {
        StockFeedYahoo controller = new StockFeedYahoo();
        StockFeedYahooFavoriteStocks subController = new StockFeedYahooFavoriteStocks();

        controller.testAttributes = testAttributesBase;
        subController.testAttributes = testAttributesBase;

        String html = controller.getFavoriteStocksHTML();
        String subHtml = subController.getHTML();

        System.assert(String.isNotBlank(html), 'Should return a non-blank string');
        System.assertEquals(html, subHtml, 'StockFeedYahooFavoriteStocks should defer to the correct method');
        System.assert(html.contains('DEFAULT_SYMBOL'), 'Should contain default symbols');
        System.assert(!html.contains('NOT_DEFAULT_SYMBOL'), 'Should not contain a non-default symbol');
    }

    private static testmethod void testGetUserPreferencesHTML_withDefaults() {
        StockFeedYahoo controller = new StockFeedYahoo();
        StockFeedYahooUserPreferences subController = new StockFeedYahooUserPreferences();

        controller.testAttributes = testAttributesBase;
        subController.testAttributes = testAttributesBase;

        String html = controller.getUserPreferencesHTML();
        String subHtml = subController.getHTML();

        System.assert(String.isNotBlank(html), 'Should return a non-blank string');
        System.assertEquals(html, subHtml, 'StockFeedUserPreferences should defer to the correct method');
        System.assert(html.contains('DEFAULT_SYMBOL'), 'Should contain default symbols');

        // Will also contain non-defaults for the checkboxes
        System.assert(html.contains('NOT_DEFAULT_SYMBOL'), 'Should contain non-default symbols');
    }

    private static testmethod void testSymbols_noAttributes() {
        StockFeedYahoo controller = new StockFeedYahoo();

        System.assertEquals(0, controller.symbols.size(), 'Symbols should be empty by default');
    }

    private static testmethod void testSymbols_withAttributes() {
        StockFeedYahoo controller = new StockFeedYahoo();

        controller.testAttributes = testAttributesBase;

        // Modifying testAttributeBase may break this test
        System.assertEquals(2, controller.symbols.size(), 'Symbols should be the correct size');
    }

    private static testmethod void testDefaultStockSymbols() {
        StockFeedYahoo controller = new StockFeedYahoo();

        controller.testAttributes = testAttributesBase;

        // Modifying testAttributeBase may break this test
        System.assertEquals(1, controller.defaultStockSymbols.size(), 'Symbols should be the correct size');
    }

    private static testmethod void testSymbolsJson() {
        StockFeedYahoo controller = new StockFeedYahoo();

        controller.testAttributes = testAttributesBase;

        System.assert(String.isNotBlank(controller.symbolsJson), 'Symbols JSON should not be blank');
    }

    private static testmethod void testMaxFavoriteSymbols_nullValue() {
        StockFeedYahoo controller = new StockFeedYahoo();

        System.assertNotEquals(null, controller.maxFavoriteSymbols,
            'Max favorite symbols should not be null by default');
    }

    private static testmethod void testMaxFavoriteSymbols_minValue() {
        StockFeedYahoo controller = new StockFeedYahoo();

        controller.testAttributes = new Map<String, String> {
            'maxFavoriteSymbols' => '-1'
        };

        System.assert(controller.maxFavoriteSymbols > 0, 'Max favorite symbols should be positive');
    }

    private static testmethod void testMaxFavoriteSymbols_maxValue() {
        StockFeedYahoo controller = new StockFeedYahoo();

        controller.testAttributes = new Map<String, String> {
            'maxFavoriteSymbols' => '500'
        };

        System.assert(controller.maxFavoriteSymbols < 500, 'Max favorite symbols should not be unreasonably high');
    }

    private static testmethod void testMessages_defaults() {
        StockFeedYahoo controller = new StockFeedYahoo();

        System.assertNotEquals(null, controller.selectStocksMessage, 'Select stocks message has a default');
        System.assertNotEquals(null, controller.tooManyStocksMessage, 'Too many stocks message has a default');
    }

    private static testmethod void testMessages_set() {
        StockFeedYahoo controller = new StockFeedYahoo();

        controller.testAttributes = new Map<String, String> {
            'selectStocksMessage' => 'selectStocksMessage',
            'tooManyStocksMessage' => 'tooManyStocksMessage'
        };

        System.assertEquals('selectStocksMessage', controller.selectStocksMessage,
            'Select stocks message should return the correct attribute value');
        System.assertEquals('tooManyStocksMessage', controller.tooManyStocksMessage,
            'Too many stocks message should return the correct attribute value');
    }

    private static testmethod void testGetHTML() {
        StockFeedYahoo controller = new StockFeedYahoo();

        String html = controller.getHTML();

        System.assertEquals('', html, 'Default getHTML should return a blank string');
    }
}
