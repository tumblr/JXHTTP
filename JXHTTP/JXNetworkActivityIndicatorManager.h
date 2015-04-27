//
//  JXNetworkActivityIndicatorManager.h
//  JXExample
//
//  Created by Bryan Irace on 4/24/15.
//  Copyright (c) 2015 JXHTTP. All rights reserved.
//

/**
 A protocol that classes who can toggle the network activity visibility indicator can conform to. This protocol provides 
 an abstraction in order to avoid referencing `+ [UIApplication sharedApplication]` from within an iOS application 
 extension.
 */
@protocol JXNetworkActivityIndicatorManager <NSObject>

/**
 A Boolean value that turns an indicator of network activity on or off.
 */
@property (nonatomic) BOOL networkActivityIndicatorVisible;

@end
