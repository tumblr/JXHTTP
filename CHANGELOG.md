### 1.0.2 -- 2013 April 04 ###

- scrapped run loop mode configurability in favor of simplicity
- connection and streams are scheduled in `NSRunLoopCommonModes`
- refactored `sharedThread` as `networkThread`


### 1.0.1 -- 2013 April 03 ###

- connection and stream run loop modes can be configured via the `runLoopModes` property
- connection and stream run loop modes default to `NSDefaultRunLoopMode`
- `JXHTTPMultipartBody` uses the host operation's `runLoopModes` and `sharedThread`
- `responseData` uses `NSDataReadingMappedIfSafe` when reading from a file
- `responseString` supports non-UTF8 encodings


### 1.0.0 -- 2013 March 21 ###

- first release!