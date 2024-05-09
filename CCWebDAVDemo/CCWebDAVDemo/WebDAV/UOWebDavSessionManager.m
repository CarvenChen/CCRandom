//
//  UOCloudRequest.m
//  Gateway_2_0
//
//  Created by Carven on 2022/11/16.
//  Copyright © 2022 Mile. All rights reserved.
//

#import "UOWebDavSessionManager.h"

static NSString * const AFWebDAVXMLDeclarationString = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>";

static NSString * AFWebDAVStringForDepth(AFWebDAVDepth depth) {
    switch (depth) {
        case AFWebDAVZeroDepth:
            return @"0";
        case AFWebDAVOneDepth:
            return @"1";
        case AFWebDAVInfinityDepth:
        default:
            return @"infinity";
    }
}

static NSString * AFWebDAVStringForLockScope(AFWebDAVLockScope scope) {
    switch (scope) {
        case AFWebDAVLockScopeShared:
            return @"shared";
        case AFWebDAVLockScopeExclusive:
        default:
            return @"exclusive";
    }
}

static NSString * AFWebDAVStringForLockType(AFWebDAVLockType type) {
    switch (type) {
        case AFWebDAVLockTypeWrite:
        default:
            return @"write";
    }
}

#pragma mark -

@implementation AFWebDAVRequestSerializer

@end

@implementation AFWebDAVSharePointRequestSerializer

#pragma mark - AFURLResponseSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:parameters error:error] mutableCopy];
    NSString *unescapedURLString = CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)([[request URL] absoluteString]), NULL, kCFStringEncodingASCII));
    mutableRequest.URL = [NSURL URLWithString:unescapedURLString];

    return mutableRequest;
}

@end

@implementation AFWebDAVMultiStatusResponseSerializer

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:207];

    return self;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        return nil;
    }

    NSMutableArray *mutableResponses = [NSMutableArray array];

    ONOXMLDocument *XMLDocument = [ONOXMLDocument XMLDocumentWithData:data error:error];
    for (ONOXMLElement *element in [XMLDocument.rootElement childrenWithTag:@"response"]) {
        AFWebDAVMultiStatusResponse *memberResponse = [[AFWebDAVMultiStatusResponse alloc] initWithResponseElement:element];
        if (memberResponse) {
            [mutableResponses addObject:memberResponse];
        }
    }

    return [NSArray arrayWithArray:mutableResponses];
}
@end


#pragma mark -

@interface AFWebDAVMultiStatusResponse ()

@end

@implementation AFWebDAVMultiStatusResponse

- (instancetype)initWithResponseElement:(ONOXMLElement *)element {
    NSParameterAssert(element);

    NSString *href = [[element firstChildWithTag:@"href" inNamespace:@"D"] stringValue];
    NSInteger status = [[[element firstChildWithTag:@"status" inNamespace:@"D"] numberValue] integerValue];

    self = [self initWithURL:[NSURL URLWithString:href] statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:nil];
    if (!self) {
        return nil;
    }

    ONOXMLElement *propElement = [[element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
    for (ONOXMLElement *resourcetypeElement in [propElement childrenWithTag:@"resourcetype"]) {
        if ([resourcetypeElement childrenWithTag:@"collection"].count > 0) {
            self.collection = YES;
            break;
        }
    }

    self.href = href;
    self.displayname = [[propElement firstChildWithTag:@"displayname" inNamespace:@"D"] stringValue];
    self.contentLength = [[[propElement firstChildWithTag:@"getcontentlength" inNamespace:@"D"] numberValue] unsignedIntegerValue];
    self.contentType = [[propElement firstChildWithTag:@"getcontenttype" inNamespace:@"D"] stringValue];
    self.creationDate = [[propElement firstChildWithTag:@"creationdate" inNamespace:@"D"] dateValue];
    self.modificationDate = [[propElement firstChildWithTag:@"modificationdate" inNamespace:@"D"] rfc_dateValue];
    self.lastModificationDate = [[propElement firstChildWithTag:@"getlastmodified" inNamespace:@"D"] rfc_dateValue];

    return self;
}

@end


#pragma mark -

@interface UOWebDavSessionManager ()

@end

@implementation UOWebDavSessionManager

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    self.namespacesKeyedByAbbreviation = @{@"D": @"DAV:"};

    self.requestSerializer = [AFWebDAVRequestSerializer serializer];
    self.responseSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[[AFWebDAVMultiStatusResponseSerializer serializer], [AFHTTPResponseSerializer serializer]]];

    self.operationQueue.maxConcurrentOperationCount = 1;

    return self;
}


- (void)contentsOfDirectoryAtURLString:(NSString *)URLString
                             recursive:(BOOL)recursive
                     completionHandler:(void (^)(NSArray *items, NSError *error))completionHandler
{
    [self PROPFIND:URLString propertyNames:nil depth:(recursive ? AFWebDAVInfinityDepth : AFWebDAVOneDepth) success:^(id responseObject) {
        if (completionHandler) {
            completionHandler(responseObject, nil);
        }
    } failure:^(NSError *error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];
}

- (void)createDirectoryAtURLString:(NSString *)URLString
       withIntermediateDirectories:(BOOL)createIntermediateDirectories
                 completionHandler:(void (^)(BOOL isSuccess, NSError *error))completionHandler
{
    __weak __typeof(self) weakself = self;
    [self MKCOL:URLString success:^(NSURLResponse *response) {
        if (completionHandler) {
            if ([NSStringFromClass([response class]) isEqualToString:@"_NSZeroData"]) {
                completionHandler(NO, nil);
            } else {
                NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
                if (res.statusCode >= 200 && res.statusCode <= 209) {
                    completionHandler(YES, nil);
                } else {
                    completionHandler(NO, nil);
                }
            }
        }
    } failure:^(NSURLResponse * _Nonnull response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        __strong __typeof(weakself) strongSelf = weakself;
        if ([httpResponse statusCode] == 409 && createIntermediateDirectories) {
            NSArray *pathComponents = [[httpResponse URL] pathComponents];
            if ([pathComponents count] > 1) {
                [pathComponents enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, __unused BOOL *stop) {
                    NSString *intermediateURLString = [[[pathComponents subarrayWithRange:NSMakeRange(0, idx)] arrayByAddingObject:component] componentsJoinedByString:@"/"];
                    [strongSelf MKCOL:intermediateURLString success:^(NSURLResponse *response) {
                        
                    } failure:^(NSURLResponse * _Nonnull response, NSError *MKCOLError) {
                        if (completionHandler) {
                            completionHandler(NO, MKCOLError);
                        }
                    }];
                }];
            }
        } else {
            if (completionHandler) {
                completionHandler(NO, error);
            }
        }
    }];
}

- (void)createFileAtURLString:(NSString *)URLString
  withIntermediateDirectories:(BOOL)createIntermediateDirectories
                     contents:(NSData *)contents
            completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler
{
    __weak __typeof(self) weakself = self;
    [self PUT:URLString data:contents success:^(NSURLResponse *response, __unused id responseObject) {
        if (completionHandler) {
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            completionHandler([res URL], nil);
        }
    } failure:^(NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        __strong __typeof(weakself) strongSelf = weakself;
        if ([res statusCode] == 409 && createIntermediateDirectories) {
            NSArray *pathComponents = [[res URL] pathComponents];
            if ([pathComponents count] > 1) {
                [strongSelf createDirectoryAtURLString:[[pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 1)] componentsJoinedByString:@"/"] withIntermediateDirectories:YES completionHandler:^(BOOL isSuccess, NSError * _Nonnull MKCOLError) {
                    if (MKCOLError) {
                        if (completionHandler) {
                            completionHandler(nil, MKCOLError);
                        }
                    } else {
                        [strongSelf createFileAtURLString:URLString withIntermediateDirectories:NO contents:contents completionHandler:completionHandler];
                    }
                }];
            }
        } else {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        }
    }];
}

- (void)removeFileAtURLString:(NSString *)URLString
            completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler
{
    [self DELETE:URLString success:^(NSURLResponse *response, id responseObject) {
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        if (completionHandler) {
            completionHandler([res URL], nil);
        }
    } failure:^(NSURLResponse *response, NSError *error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];
}


#pragma mark -
- (NSURLSessionDataTask *)PROPFIND:(NSString *)URLString
                       propertyNames:(NSArray *)propertyNames
                               depth:(AFWebDAVDepth)depth
                             success:(void (^)(id responseObject))success
                             failure:(void (^)(NSError *error))failure
{
    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
    {
        [mutableXMLString appendString:@"<D:propfind"];
        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
            [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
        }];
        [mutableXMLString appendString:@">"];

        if (propertyNames) {
            [propertyNames enumerateObjectsUsingBlock:^(NSString *property, __unused NSUInteger idx, __unused BOOL *stop) {
                [mutableXMLString appendFormat:@"<%@/>", property];
            }];
        } else {
            [mutableXMLString appendString:@"<D:allprop/>"];
        }

        [mutableXMLString appendString:@"</D:propfind>"];
    }

    NSError *serializationError = nil;
    NSString *path = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PROPFIND" URLString:path parameters:nil error:&serializationError];
    [request setValue:AFWebDAVStringForDepth(depth) forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type:"];
    [request setHTTPBody:[mutableXMLString dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success(responseObject);
            }
        }
    }];
    [dataTask resume];
    
    return dataTask;
}

- (NSURLSessionDataTask *)MKCOL:(NSString *)URLString
                          success:(void (^)(NSURLResponse *response))success
                          failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    
    NSError *serializationError = nil;
    NSString *path = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"MKCOL" URLString:path parameters:nil error:&serializationError];
    NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {

        if (error) {
            if (failure) {
                failure(response, error);
            }
        } else {
            if (success) {
                success(response);
            }
        }
    }];
    [dataTask resume];
    
    return dataTask;
}

#pragma mark -
- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                         data:(NSData *)data
                      success:(void (^)(NSURLResponse *response, id responseObject))success
                      failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    
    NSError *serializationError = nil;
    NSString *path = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT" URLString:path parameters:nil error:&serializationError];
    request.HTTPBody = data;
    NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {

        if (error) {
            if (failure) {
                failure(response, error);
            }
        } else {
            if (success) {
                success(response, responseObject);
            }
        }
    }];
    [dataTask resume];
    
    return dataTask;
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      success:(void (^)(NSURLResponse *response, id responseObject))success
                      failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    
    NSError *serializationError = nil;
    NSString *path = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"DELETE" URLString:path parameters:nil error:&serializationError];
    NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(response, error);
            }
        } else {
            if (success) {
                success(response, responseObject);
            }
        }
    }];
    [dataTask resume];
    
    return dataTask;
}

@end
