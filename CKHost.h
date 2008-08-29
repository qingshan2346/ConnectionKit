/*
 Copyright (c) 2006, Greg Hulands <ghulands@mac.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list 
 of conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright notice, this 
 list of conditions and the following disclaimer in the documentation and/or other 
 materials provided with the distribution.
 
 Neither the name of Greg Hulands nor the names of its contributors may be used to 
 endorse or promote products derived from this software without specific prior 
 written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
 SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
 BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

@protocol AbstractConnectionProtocol;
@class CKHostCategory;

@interface CKHost : NSObject <NSCoding, NSCopying>
{
	NSString *_UUID;
	NSString *_host;
	NSString *_port;
	NSString *_username;
	NSString *_password;
	NSString *_connectionType;
	NSString *_initialPath;
	NSURL *_URL;
	NSString *_description;
	NSImage	 *_icon;
	NSMutableDictionary *_properties;
	
	id _userInfo;
	
	CKHostCategory *_category; // not retained
}

@property (readonly) NSString *UUID;
@property (readonly) NSString *uuid; //Same as UUID
@property (readonly) NSString *host;
@property (readonly) NSString *port;
@property (readonly) NSString *username;
@property (readonly) NSString *password;
@property (readonly) NSString *connectionType;
@property (readonly) NSString *initialPath;
@property (readonly) NSURL *URL;
@property (readonly) NSString *annotation;
@property (readonly) NSImage *icon;
@property (readonly) id userInfo;
@property (readonly) CKHostCategory *category;

- (id)init;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)plistRepresentation;

- (void)setHost:(NSString *)host;
- (void)setPort:(NSString *)port;
- (void)setUsername:(NSString *)username;
- (void)setPassword:(NSString *)password;
- (void)setConnectionType:(NSString *)type;
- (void)setInitialPath:(NSString *)path;
- (void)setURL:(NSURL *)url;
- (void)setAnnotation:(NSString *)description;
- (void)setUserInfo:(id)ui;
- (void)setIcon:(NSImage *)icon;

- (NSString *)uuid;
- (BOOL)isAbsoluteInitialPath;
- (NSURL *)baseURL; // doesn't contain initialPath
- (NSString *)annotation;
- (BOOL)isEditable;
- (NSImage *)iconWithSize:(NSSize)size;

- (void)setCategory:(CKHostCategory *)cat;

// returns a new autoreleased connection of this type;
- (id <AbstractConnectionProtocol>)connection; 

- (void)setProperty:(id)property forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;

- (NSString *)createDropletAtPath:(NSString *)path;

- (BOOL)canConnect;

- (void)didChange;

@end

extern NSString *CKHostChanged;
