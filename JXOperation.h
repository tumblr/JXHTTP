/**
 A lightweight `NSOperation` subclass that adds several basic but useful
 features that apply to any kind of operation. Suitable as a base class for
 all the operation subclasses in an application.
 
 `JXOperation` improves upon vanilla `NSOperation` by providing the following:
 
 - Concurrency support to allow the use of asynchronous APIs, as specified in
   the `NSOperation` "subclassing notes" and following the recommendations of
   Dave Dribin:
 
   <http://dribin.org/dave/blog/archives/2009/05/05/concurrent_operations>

   <http://dribin.org/dave/blog/archives/2009/09/13/snowy_concurrent_operations>
 
 - An option to force the operation to run on the main thread, even when
   started from a background thread or queue.

 - An option to continue running the operation when the application enters the
   background.
 */

@interface JXOperation : NSOperation

/// @name Operation State

/**
 `YES` while the operation is executing and NO once it has finished.
 */
@property (assign, readonly) BOOL isExecuting;

/**
 `YES` once the operation has finished.
 */
@property (assign, readonly) BOOL isFinished;

/**
 `YES` once the operation has started.
 */
@property (assign, readonly) BOOL didStart;

/// @name Background Options

/**
 When `YES`, the operation runs on the main thread even if it was started from a
 background thread or operation queue. When `NO`, the operation will run on
 whatever thread it was started from (which may still be the main thread).
 This property can be changed up until the operation starts. Defaults to `NO`.
 */
@property (assign) BOOL startsOnMainThread;

/**
 Upon being set to `YES`, retrieves a `UIBackgroundTaskIdentifier` to cause the
 operation to continue running when the application enters the background. The 
 operation will relinquish the task identifier when it has finished or been
 cancelled and allow the application to terminate.
 */
@property (assign) BOOL continuesInAppBackground;

/// @name Initialization

/**
 Creates a new operation.
 @returns An autoreleased operation.
 */
+ (id)operation;

/// @name Starting and Finishing

/**
 Starts the operation and blocks the calling thread until it has finished. The
 operation is not guaranteed to run on the same thread as the caller.
 */
- (void)startAndWaitUntilFinished;

/**
 Ends the operation. Subclasses must eventually call this method to cause the
 operation to finish (typically at the end of their main method).
 */
- (void)finish;

@end
