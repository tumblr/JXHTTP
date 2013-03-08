/**
 `JXOperation` is an abstract `NSOperation` subclass that implements all the
 methods necessary for what Apple calls "concurrent" operations (see the sections
 titled "Subclassing Notes" and "Multicore Considerations" in the `NSOperation`
 class reference, this subclass does all of it for you.)
 
 The main advantage of concurrent operations is that they allow for the use of
 asynchronous APIs. Normally, when the `main` method of an `NSOperation` exits,
 the operation flags itself as finished and deallocation is imminent. In a
 concurrent operation, nothing happens when `main` exits and it's up to you to
 manually report that the operation is finished via KVO. In the meantime you can
 wait for delegate callbacks or do anything else that requires waiting for the
 runloop to turn over.
 
 Unfortunately, `NSOperation` has some quirks and ensuring thread safety as
 the operation changes state can be tricky. `JXOperation` makes it easy by
 providing a simple `finish` method that can be called at any time from any
 thread without worrying about the operation's current state.
 
 Heavily inspired by Dave Dribin, and building on his work detailed here:
 
 <http://dribin.org/dave/blog/archives/2009/05/05/concurrent_operations>
 */

@interface JXOperation : NSOperation

/// @name Operation State

/**
 `YES` while the operation is executing and `NO` once it has finished.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) BOOL isExecuting;

/**
 `YES` if the operation has finished, otherwise `NO`.
 
  Safe to access from any thread at any time.
 */
@property (assign, readonly) BOOL isFinished;

/**
 Upon being set to `YES`, retrieves a `UIBackgroundTaskIdentifier` to cause the
 operation to continue running when the application enters the background.
 Changing this property to `YES` after the operation starts has no effect.
 
 Safe to access from any thread at any time.
 */
@property (assign) BOOL continuesInAppBackground;

/// @name Initialization

/**
 Creates a new operation.
 
 @returns An autoreleased operation.
 */
+ (instancetype)operation;

/// @name Starting and Finishing

/**
 Starts the operation and blocks the calling thread until it has finished.
 */
- (void)startAndWaitUntilFinished;

/**
 Subclasses should override this method (and call super) rather than overriding
 `finish`. In addition, this method should never be called manually. It is
 guaranteed to be called exactly one time from one thread just before the operation
 is marked as finished (and thus potentially deallocated). If your operation
 has any cleanup to do before it disappears forever, do it here.
 */
- (void)willFinish;

/**
 Ends the operation. Subclasses must eventually call this method to cause the
 operation to finish (typically at the end of their main method). To ensure thread
 saftey, do not override this method (use `willFinish` instead, see above). Once
 the operation has finished to do not attempt to access any of its properties as it
 may be released by a queue or other retaining object from a different thread.
 
 This method is safe to call multiple times from any thread at any time, including
 before the operation has started.
 */
- (void)finish;

@end
