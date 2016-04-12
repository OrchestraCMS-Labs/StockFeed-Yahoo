/**
 * Processes actions related to the content templates "StockFeedYahooFavorites" and "StockFeedUserPreferences".
 */
global with sharing class StockFeedYahooService implements cms.ServiceInterface {
    public static final String PREFERENCE_COOKIE_NAME = 'stockFeedSymbols';

    /** Stores the template for a YQL (Yahoo Query Language) request URL */
    private static final String URL_TEMPLATE;
    private static final String SYMBOL_LIST_TOKEN = '_symbolList_';

    static {
        String yqlQuery = 'SELECT symbol, LastTradePriceOnly, Change, PercentChange, LastTradeDate, LastTradeTime '
            + 'FROM yahoo.finance.quotes '
            + 'WHERE symbol IN (' + SYMBOL_LIST_TOKEN + ')';

        URL_TEMPLATE = 'https://query.yahooapis.com/v1/public/yql'
            + '?q=' + EncodingUtil.urlEncode(yqlQuery, 'UTF-8')
            + '&format=json'
            + '&env=' + EncodingUtil.urlEncode('store://datatables.org/alltableswithkeys', 'UTF-8');
    }

    /**
     * Core handler method for retrieving stock quotes from Yahoo's service, and for saving/loading a user's
     * preferred stock symbols.
     *
     * @param params a map of parameters including at minimum a value for 'action'
     * @return a JSON-serialized response string
     */
    public String executeRequest(Map<String, String> params) {
        String action = params.get('action');

        try {
             if(action == 'getUserQuotes') {
                return getUserQuotesJSON(params);
            } else if(action == 'getQuotes') {
                return getQuotesJSON(params);
            } else if(action == 'getUserQuotesPreferences') {
                return getUserQuotesPreferencesJSON(params);
            } else if(action == 'postUserQuotesPreferences') {
                return postUserQuotesPreferencesJSON(params);
            }
        } catch(Exception e) {
            // Unexpected error
            String message = e.getMessage();

            return '{"success":false,"message":' + JSON.serialize(message) + '}';
        }

        // No actions matched and no error occurred
        return '{"success":false,"message":"Invalid Action"}';
    }

    /** Represents an individual quote for a symbol. */
    public class StockQuote {
        public String symbol;
        public Decimal quote;
        public Decimal change;
        public Decimal percentChange;

        public StockQuote(Map<String, Object> data) {
            this.symbol = (String)data.get('symbol');

            if(data.get('LastTradePriceOnly') != null) {
                this.quote = Decimal.valueOf((String)data.get('LastTradePriceOnly'));
            }

            if(data.get('Change') != null) {
                this.change = Decimal.valueOf((String)data.get('Change'));
            }

            if(data.get('PercentChange') != null) {
                // % Change is formatted as {decimal}%
                String percentString = (String)data.get('PercentChange');
                String decimalString = percentString.substring(0, percentString.length() - 1);

                this.percentChange = Decimal.valueOf(decimalString);
            }
        }
    }

    public class StockFeedYahooServiceException extends Exception {}

    private String getUserQuotesJSON(Map<String, String> params) {
        List<String> defaults = new List<String>();

        try {
            defaults = (List<String>)JSON.deserialize(params.get('defaults'), List<String>.class);
        } catch(JSONException e) {
            System.debug(e);
        }

        return '{"success":true,"quotes":' + JSON.serialize(getUserQuotes(defaults)) + '}';
    }

    /**
     * Fetches a set of stocks quotes based on the current user's preferences.
     *
     * <p>If a user has no saved preferences the list of symbols passed
     * in <pre>defaults</pre> will be fetched instead.</p>
     *
     * @param defaults a list of symbols to fetch as a fallback if the current user has no saved preferences
     * @return a map of symbols to {@link #StockQuote} instances
     */
    public Map<String, StockQuote> getUserQuotes(List<String> defaults) {
        List<String> symbols = defaults;

        Cookie userPreferenceCookie = ApexPages.currentPage().getCookies().get(PREFERENCE_COOKIE_NAME);
        if(userPreferenceCookie != null) {
            try {
                symbols = (List<String>)JSON.deserialize(userPreferenceCookie.getValue(), List<String>.class);
            } catch(JSONException e) {
                System.debug(e);
            }
        }

        return getQuotes(symbols);
    }

    private String getQuotesJSON(Map<String, String> params) {
        List<String> symbols;

        try {
            symbols = (List<String>)JSON.deserialize(params.get('symbols'), List<String>.class);
        } catch(JSONException e) {
            System.debug(e);
            return '{"success":false,"message":"Invalid list of symbols supplied."}';
        }

        Map<String, StockQuote> quotes = getQuotes(symbols);
        return '{"success":true,"quotes":' + JSON.serialize(quotes) + '}';
    }

    /**
     * Fetches a set of stocks quotes.
     *
     * @param symbols a list of symbols to fetch
     * @return a map of symbols to {@link #StockQuote} instances
     */
    public Map<String, StockQuote> getQuotes(List<String> symbols) {
        String response = calloutQuotes(symbols);

        Map<String, StockQuote> quotes = parseQuotesResponse(response);

        return quotes;
    }

    /** Performs an HTTP callout to fetch quote information from Yahoo for a list of symbols */
    private String calloutQuotes(List<String> symbols) {
        String symbolsList = '"' + String.join(symbols, '","') + '"';
        String requestUrl = URL_TEMPLATE.replaceAll(SYMBOL_LIST_TOKEN, symbolsList);

        System.debug('Requesting ' + requestUrl);

        HTTPRequest quoteRequest = new HTTPRequest();
        quoteRequest.setEndpoint(requestUrl);
        quoteRequest.setCompressed(true);
        quoteRequest.setMethod('GET');

        HTTP http = new HTTP();
        HTTPResponse quoteResponse;

        try {
            quoteResponse = http.send(quoteRequest);
        } catch(Exception e) {
            System.debug(e);
            throw new StockFeedYahooServiceException('Quote fetch failed: \n\n' + e.getMessage());
        }

        if(quoteResponse.getStatusCode() != 200) {
            throw new StockFeedYahooServiceException(
                'Quote fetch failed: \n\n' + quoteResponse.getStatusCode() + ': ' + quoteResponse.getStatus()
            );
        }

        return quoteResponse.getBody();
    }

    /** Parses the response from a call to calloutQuotes */
    private Map<String, StockQuote> parseQuotesResponse(String response) {
        /* Sample response for 1 symbol:
         *  {
         *      "query": {
         *          "count": 1,
         *          "results": {
         *              "quote": {
         *                  ...
         *              }
         *          }
         *      }
         *  }
         *
         * Sample response for 2+ symbols:
         *  {
         *      "query": {
         *          "count": 1,
         *          "results": {
         *              "quote": [
         *                  {
         *                      ...
         *                  }, {
         *                      ...
         *                  }
         *              ]
         *          }
         *      }
         *  }
         */

        Map<String, StockQuote> quoteResults = new Map<String, StockQuote>();
        try {
            Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response);
            Map<String, Object> queryObject = (Map<String, Object>)responseObject.get('query');
            Map<String, Object> resultsObject = (Map<String, Object>)queryObject.get('results');

            Integer resultCount = (Integer)queryObject.get('count');

            if(resultCount == 1) {
                Map<String, Object> quoteData = (Map<String, Object>)resultsObject.get('quote');
                StockQuote quote = new StockQuote(quoteData);
                quoteResults.put(quote.symbol, quote);
            } else if(resultCount >= 2) {
                List<Object> quotesList = (List<Object>)resultsObject.get('quote');
                for(Integer i = 0; i < quotesList.size(); i++) {
                    Map<String, Object> quoteData = (Map<String, Object>)quotesList.get(i);
                    StockQuote quote = new StockQuote(quoteData);
                    quoteResults.put(quote.symbol, quote);
                }
            }
        } catch(JSONException e) {
            System.debug(e);
            System.debug('Response: ' + response);
            throw new StockFeedYahooServiceException('Unexpected stock feed response - parsing failed');
        }

        return quoteResults;
    }

    private String getUserQuotesPreferencesJSON(Map<String, String> params) {
        // Doesn't take any parameters

        List<String> preferences = getUserQuotesPreferences();

        return '{"success":true,"preferences":' + JSON.serialize(preferences) + '}';
    }

    /**
     * Retrieves the current user's favourite stock symbols
     *
     * @return a list of stock symbols, or null if the user has no saved favourites
     */
    public List<String> getUserQuotesPreferences() {
        Cookie preferencesCookie = ApexPages.currentPage().getCookies().get(PREFERENCE_COOKIE_NAME);

        List<String> preferences = null;

        try {
            preferences = (List<String>)JSON.deserialize(preferencesCookie.getValue(), List<String>.class);
        } catch(NullPointerException e) {
            // No preferences cookie was found
        } catch(JSONException e) {
            // The preferences cookie wasn't valid JSON
            System.debug(e);
        }

        return preferences;
    }

    private String postUserQuotesPreferencesJSON(Map<String, String> params) {
        String preferencesString = params.get('preferences');
        List<String> preferences = new List<String>();

        try {
            preferences = (List<String>)JSON.deserialize(preferencesString, List<String>.class);
        } catch(JSONException e) {
            return '{"success":false,"message":"Invalid preferences string"}';
        }

        postUserQuotesPreferences(preferences);

        return '{"success":true}';
    }

    /**
     * Saves a list of symbols as the current user's favourite symbols.
     *
     * @param preferences a list of symbols
     */
    public void postUserQuotesPreferences(List<String> preferences) {
        Cookie preferencesCookie = new Cookie(
            PREFERENCE_COOKIE_NAME, // name
            JSON.serialize(preferences), // value
            null, // path, null is root
            604800, // max-age, 1 week in seconds
            true // isSecure
        );

        ApexPages.currentPage().setCookies(new Cookie[] { preferencesCookie });
    }

    public StockFeedYahooService() {}

    public static Type getType() {
        return StockFeedYahooService.class;
    }
}
