@isTest
private with sharing class StockFeedYahooService_Test {
    private static StockFeedYahooService service = new StockFeedYahooService();

    private static List<String> oneSymbol = new List<String> { 'CRM' };

    private static List<String> twoSymbols = new List<String> {
        'MSFT',
        'AAPL'
    };

    private static final String INVALID_JSON = '[invalid json';

    private static QuoteCalloutSymbolChecker symbolCheckerMock;

    private static void setExpectedSymbolResponse(List<String> symbols) {
        if(symbolCheckerMock == null) {
            symbolCheckerMock = new QuoteCalloutSymbolChecker();
            Test.setMock(HTTPCalloutMock.class, symbolCheckerMock);
        }

        symbolCheckerMock.symbols = symbols;
    }

    private static testmethod void testExecuteRequest_getUserQuotesValidInput() {
        setExpectedSymbolResponse(twoSymbols);

        Map<String, String> params = new Map<String, String> {
            'action' => 'getUserQuotes',
            'defaults' => JSON.serialize(twoSymbols)
        };

        String response = service.executeRequest(params);

        System.assert(response.contains('"success":true'), 'JSON response should be successful');
    }

    private static testmethod void testExecuteRequest_getUserQuotesInvalidInput() {
        setExpectedSymbolResponse(new List<String>());

        Map<String, String> params = new Map<String, String> {
            'action' => 'getUserQuotes',
            'defaults' => INVALID_JSON
        };

        String response = service.executeRequest(params);

        System.assert(response.contains('"success":true'), 'JSON response should be successful');
    }

    private static testmethod void testExecuteRequest_getQuotesValidInput() {
        setExpectedSymbolResponse(twoSymbols);

        Map<String, String> params = new Map<String, String> {
            'action' => 'getQuotes',
            'symbols' => JSON.serialize(twoSymbols)
        };

        String response = service.executeRequest(params);

        System.assert(response.contains('"success":true'), 'JSON response should be successful');
        for(String symbol : twoSymbols) {
            System.assert(response.contains(symbol), 'JSON response should contain the requested symbols');
        }
    }

    private static testmethod void testExecuteRequest_getQuotesInvalidInput() {
        // No HTTP mock - the callout should never happen
        Map<String, String> params = new Map<String, String> {
            'action' => 'getQuotes',
            'symbols' => INVALID_JSON
        };

        String response = service.executeRequest(params);

        System.assert(response.contains('"success":false'), 'JSON response should not be successful');
    }

    private static testmethod void testExecuteRequest_postUserQuotesPreferencesValidInput() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'postUserQuotesPreferences',
            'preferences' => JSON.serialize(oneSymbol)
        };

        String response = service.executeRequest(params);

        System.assert(response.contains('"success":true'), 'JSON response should be successful');

        // Preference is set to oneSymbol. We'll request with twoSymbols as the default
        setExpectedSymbolResponse(oneSymbol);

        service.getUserQuotes(twoSymbols);
    }

    private static testmethod void testExecuteRequest_postUserQuotesPreferencesInvalidInput() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'postUserQuotesPreferences',
            'preferences' => INVALID_JSON
        };

        String response = service.executeRequest(params);

        System.assert(response.contains('"success":false'), 'JSON response should be successful');

        // Preference should NOT be set. We'll request with twoSymbols as the default
        setExpectedSymbolResponse(twoSymbols);

        service.getUserQuotes(twoSymbols);
    }

    private static testmethod void testExecuteRequest_getUserQuotesPreferences() {
        List<String> preferences = oneSymbol;

        Map<String, String> params = new Map<String, String> {
            'action' => 'getUserQuotesPreferences'
        };

        String response = service.executeRequest(params);

        System.assert(response.contains('"success":true'),
            'JSON response should be successful before setting preferences');

        service.postUserQuotesPreferences(preferences);

        response = service.executeRequest(params);

        System.assert(response.contains('"success":true'),
            'JSON response should be successful after setting preferences');
    }

    private static testmethod void testExecuteRequest_invalidAction() {
        // No HTTP mock - no callout should happen
        Map<String, String> params = new Map<String, String> {
            'action' => 'invalid_action'
        };

        String response = service.executeRequest(params);

        System.assert(response.contains('"success":false'), 'JSON response should not be successful');
    }

    private static testmethod void testGetUserQuotes_withoutPreference() {
        // We'll pass twoSymbols as the default to fetch so we expect that response
        setExpectedSymbolResponse(twoSymbols);

        Map<String, StockFeedYahooService.StockQuote> quotes = service.getUserQuotes(twoSymbols);

        System.assertNotEquals(null, quotes, 'The returned quote map should not be null');
        System.assertEquals(2, quotes.size(), 'Passing two symbols as the default should return two quotes');
        for(String symbol : twoSymbols) {
            System.assert(quotes.containsKey(symbol), 'The returned quote map should contain the requested symbols.');
        }
    }

    private static testmethod void testGetUserQuotes() {
        // Note that this also tests postUserQuotes
        List<String> userPreference = oneSymbol;

        // Baseline - verify that defaults are used with no preference
        setExpectedSymbolResponse(twoSymbols);
        service.getUserQuotes(twoSymbols);

        service.postUserQuotesPreferences(userPreference);

        // We've set a user preference - verify that it's sent instead of the default
        setExpectedSymbolResponse(userPreference);
        service.getUserQuotes(twoSymbols);
    }

    private static testmethod void testGetQuotes_oneSymbol() {
        setExpectedSymbolResponse(oneSymbol);

        Map<String, StockFeedYahooService.StockQuote> quotes = service.getQuotes(oneSymbol);

        System.assertNotEquals(null, quotes, 'The returned quote map should not be null');
        System.assertEquals(1, quotes.keySet().size(), 'Getting a quote for one symbol should return a single quote');
        System.assert(quotes.containsKey(oneSymbol[0]), 'The returned quote map should contain the requested symbol');

        StockFeedYahooService.StockQuote singleQuote = quotes.get(oneSymbol[0]);

        System.assertEquals(oneSymbol[0], singleQuote.symbol,
            'The returned StockQuote should contain the requested symbol');
        System.assertNotEquals(null, singleQuote.quote, 'The returned quote should contain a quote amount');
        System.assertNotEquals(null, singleQuote.change, 'The returned quote should contain a change amount');
        System.assertNotEquals(null, singleQuote.percentChange, 'The returned quote should contain a percent change');
    }

    private static testmethod void testGetQuotes_twoSymbols() {
        setExpectedSymbolResponse(twoSymbols);
        Map<String, StockFeedYahooService.StockQuote> quotes = service.getQuotes(twoSymbols);

        System.assertNotEquals(null, quotes, 'The returned quote map should not be null');
        System.assertEquals(2, quotes.size(), 'Getting quotes for two symbols should return two quotes');
        for(String symbol : twoSymbols) {
            System.assert(quotes.containsKey(symbol), 'The returned quote map should contain the requested symbols.');
        }
    }

    private static testmethod void testGetQuotes_calloutException() {
        Test.setMock(HTTPCalloutMock.class, new QuoteCalloutExceptionMock());

        try {
            Map<String, StockFeedYahooService.StockQuote> quotes = service.getQuotes(twoSymbols);
            System.assert(false, 'Should throw an exception if the HTTP request fails');
        } catch(StockFeedYahooService.StockFeedYahooServiceException e) {
            // Expected
        }
    }

    private static testmethod void testGetQuotes_httpErrorResponse() {
        Test.setMock(HTTPCalloutMock.class, new QuoteCalloutFailureMock());

        try {
            Map<String, StockFeedYahooService.StockQuote> quotes = service.getQuotes(twoSymbols);
            System.assert(false, 'Should throw an exception if the HTTP status code is not 200');
        } catch(StockFeedYahooService.StockFeedYahooServiceException e) {
            // Expected
        }
    }

    private static testmethod void testGetUserQuotesPreferences() {
        List<String> retrievedPreferences;

        retrievedPreferences = service.getUserQuotesPreferences();

        System.assertEquals(null, retrievedPreferences, 'Should return null if no preferences have been saved');

        List<String> savedPreferences = oneSymbol;
        service.postUserQuotesPreferences(savedPreferences);

        retrievedPreferences = service.getUserQuotesPreferences();

        System.assertNotEquals(null, retrievedPreferences, 'Should not return null after preferences have been saved');
        System.assertEquals(savedPreferences.size(), retrievedPreferences.size(),
            'Should return the same size list as the saved preferences');
        System.assertEquals(SavedPreferences[0], retrievedPreferences[0],
            'Should return the same list contents as the saved preferences');
    }

    private static testmethod void testGetType() {
        System.assertEquals(StockFeedYahooService.class, StockFeedYahooService.getType());
    }

    private class QuoteCalloutSymbolChecker implements HttpCalloutMock {
        public List<String> symbols = new List<String>();

        public HTTPResponse respond(HTTPRequest req) {
            for(String symbol : symbols) {
                System.assert(req.getEndpoint().contains(symbol), 'Request should contain the symbol ' + symbol);
            }

            // Use an error response - we don't care about a response in this case
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json; charset=UTF-8');

            if(symbols.size() == 0) {
                res.setBody('{"query":{"count":0,"created":"2016-04-01T00:00:00Z","lang":"en-US","results":null}}');
            } else if(symbols.size() == 1) {
                res.setBody(
                    '{"query":{"count":1,"created":"2016-04-01T00:00:00Z","lang":"en-US","results":{'
                    + '"quote":' + buildQuoteResult(symbols[0]) + '}}}'
                );
            } else {
                String body = '{"query":{"count":2,"created":"2016-04-01T00:00:00Z","lang":"en-US","results":{'
                    + '"quote":[';

                for(Integer i = 0; i < symbols.size(); i++) {
                    if(i > 0) {
                        body += ',';
                    }

                    body += buildQuoteResult(symbols[i]);
                }

                body += ']}}}';

                res.setBody(body);
            }

            return res;
        }

        private String buildQuoteResult(String symbol) {
            return '{"symbol":"' + symbol + '","Change":"-0.05","LastTradeDate":"4/1/2016",'
                + '"LastTradePriceOnly":"100.00","LastTradeTime":"8:00pm","PercentChange":"-0.1%"}';
        }
    }

    private class QuoteCalloutExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('HTTP Callout Failed');

            return null;
        }
    }

    private class QuoteCalloutFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(500); // Internal server error

            return res;
        }
    }
}
