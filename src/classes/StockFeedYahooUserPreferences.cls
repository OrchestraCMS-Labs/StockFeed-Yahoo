/**
 * Provides a single entrypoint for OrchestraCMS to render a "StockFeedYahooUserPreferences" content template.
 */
global with sharing class StockFeedYahooUserPreferences extends StockFeedYahoo {
    /** Delegates rendering to {@link StockFeedYahoo#getUserPreferencesHTML()} */
    global virtual override String getHTML() {
        return getUserPreferencesHTML();
    }
}
