# Stock Feed Yahoo

<!-- MarkdownTOC depth=3 -->

1. [Summary](#summary)
    1. [Compatibility](#compatibility)
    1. [Prerequisites](#prerequisites)
    1. [Deployment](#deployment)
    1. [Configuration](#configuration)
1. [Versioning](#versioning)
    1. [Major Versions](#major-versions)
    1. [Minor Versions](#minor-versions)
    1. [Patch Versions](#patch-versions)

<!-- /MarkdownTOC -->

<a name="summary"></a>
## Summary

The Stock Feed Yahoo content type provides a *Favorite Stocks* template to load stock quotes in a format suitable for a dashboard or common status area on a website. It also provides the *User Preferences* template that allows a user to choose their favourite symbols from a predefined list.

<a name="compatibility"></a>
### Compatibility

This content type requires a minimum of OrchestraCMS package 7.184 (Winter 2016, v7.3 Build #7.184).

<a name="prerequisites"></a>
### Prerequisites

1. A compatible version of OrchestraCMS is installed in the target Salesforce organization.
2. A site has been created in OrchestraCMS.

<a name="deployment"></a>
### Deployment

1. Deploy the following Apex classes to the target Salesforce organization
    1. StockFeedYahoo.cls
    2. StockFeedYahoo_Test.cls
    3. StockFeedYahooFavoriteStocks.cls
    4. StockFeedYahooService.cls
    5. StockFeedYahooService_Test.cls
    6. StockFeedYahooUserPreferences.cls
2. Zip the contents of resource-bundles/StockFeedYahoo.resource and deploy the compressed file as StockFeedYahoo.resource
3. Deploy the following Visualforce pages to the target Salesforce organization
    1. StockFeedYahoo_Edit.page

<a name="configuration"></a>
### Configuration

Create OrchestraCMS Content Layout records with the following field values:

```
Name : StockFeedUserPreferences
Label : Stock Feed User Preferences
Controller : StockFeedUserPreferences
isPageCacheable : true
isContentCacheable : true
Visualforce Edit : c__StockFeedYahoo_Edit
```

```
Name : StockFeedYahooFavorites
Label : Stock Feed Yahoo Favorites
Controller : StockFeedYahooFavorites
isPageCacheable : true
isContentCacheable : true
Visualforce Edit : c__StockFeedYahoo_Edit
```

On the target OrchestraCMS site create the following content type(s) and add content templates as indicated.

```
Name: StockFeedYahoo
Label: Stock Feed Yahoo
Templates:
    Stock Feed User Preferences, autocreate, default
    Stock Feed Yahoo Favorites, autocreate
```

<a name="versioning"></a>
## Versioning

Versions of this content type are numbered MAJOR.MINOR.PATCH.

Any modifications to this code outside of this repository are customizations and will impact upgradeability.

<a name="major-versions"></a>
### Major Versions

Major versions introduce new functionality and may break existing implementations.

<a name="minor-versions"></a>
### Minor Versions

Minor versions introduce new functionality, but will not break existing implementations.

<a name="patch-versions"></a>
### Patch Versions

Patches correct defects in the implementation and do not introduce new functionality.
