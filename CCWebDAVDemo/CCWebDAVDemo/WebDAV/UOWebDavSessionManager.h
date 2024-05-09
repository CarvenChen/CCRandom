//
//  UOCloudRequest.h
//  Gateway_2_0
//
//  Created by Carven on 2022/11/16.
//  Copyright © 2022 Mile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "ONOXMLDocument.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, AFWebDAVDepth) {
    AFWebDAVZeroDepth = 0,
    AFWebDAVOneDepth = 1,
    AFWebDAVInfinityDepth = (NSUIntegerMax - 1),
};

typedef NS_OPTIONS(NSUInteger, AFWebDAVLockType) {
    AFWebDAVLockTypeWrite = 0,
};

typedef NS_ENUM(NSUInteger, AFWebDAVLockScope) {
    AFWebDAVLockScopeExclusive = 0,
    AFWebDAVLockScopeShared = 1,
};


#pragma mark -

/**
 `AFWebDAVRequestSerializer` is the default request serializer of `AFWebDAVManager`.
 */
@interface AFWebDAVRequestSerializer : AFHTTPRequestSerializer

@end

/**
 `AFWebDAVSharePointRequestSerializer` is a request serializer for `AFWebDAVManager` to be used to accomodate differences in how WebDAV is implemented on SharePoint servers.
 */
@interface AFWebDAVSharePointRequestSerializer : AFWebDAVRequestSerializer

@end

#pragma mark -

/**
 `AFWebDAVMultiStatusResponseSerializer` is the default response serializer of `AFWebDAVManager`, which automatically handles any multi-status responses from a WebDAV server.
 
 @discussion The response object of `AFWebDAVMultiStatusResponseSerializer` is an array of `AFWebDAVMultiStatusResponse` objects.
 */
@interface AFWebDAVMultiStatusResponseSerializer : AFHTTPResponseSerializer

@end

/**
 `AFWebDavMultiStatusResponse` is a subclass of `NSHTTPURLResponse` that is returned from multi-status responses sent by WebDAV servers.
 */
@interface AFWebDAVMultiStatusResponse : NSHTTPURLResponse

@property (nonatomic, assign, getter=isCollection) BOOL collection;
@property (nonatomic, copy) NSString *href;
@property (nonatomic, copy) NSString *displayname;
@property (nonatomic, assign) NSUInteger contentLength;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, copy) NSDate *modificationDate;
@property (nonatomic, copy) NSDate *lastModificationDate;
@property (nonatomic, copy) NSDate *creationDate;



- (instancetype)initWithResponseElement:(ONOXMLElement *)element;

@end

#pragma mark -
@interface UOWebDavSessionManager : AFHTTPSessionManager

@property (nonatomic, strong) NSDictionary *namespacesKeyedByAbbreviation;

- (void)contentsOfDirectoryAtURLString:(NSString *)URLString
                             recursive:(BOOL)recursive
                     completionHandler:(void (^)(NSArray *items, NSError *error))completionHandler;

- (void)createDirectoryAtURLString:(NSString *)URLString
       withIntermediateDirectories:(BOOL)createIntermediateDirectories
                 completionHandler:(void (^)(BOOL isSuccess, NSError *error))completionHandler;

- (void)createFileAtURLString:(NSString *)URLString
  withIntermediateDirectories:(BOOL)createIntermediateDirectories
                     contents:(NSData *)contents
            completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler;

- (void)removeFileAtURLString:(NSString *)URLString
            completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler;
@end

NS_ASSUME_NONNULL_END
