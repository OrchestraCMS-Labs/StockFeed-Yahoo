/**
 * Provides a single entrypoint for OrchestraCMS to render a "StockFeedYahooFavoriteStocks" content template.
 */
global with sharing class StockFeedYahooFavoriteStocks extends StockFeedYahoo {
    /** Delegates rendering to {@link StockFeedYahoo#getFavoriteStocksHTML()} */
    global virtual override String getHTML() {
        return getFavoriteStocksHTML();
    }
}
