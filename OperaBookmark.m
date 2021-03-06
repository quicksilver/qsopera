//
//  OperaBookmark.m
//  OperaParser
//
/* (c) Copyright 2009 Eric Doughty-Papassideris. All Rights Reserved.

	This file is part of QSOpera.

    QSOpera is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    QSOpera is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with QSOpera.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "OperaBookmark.h"

@implementation OperaBookmark

@synthesize title=_sTitle, icon=_sIcon, URL=_sURL, description=_sDescription, keywords=_sKeywords;

/* Opera icon cache */
NSImage *OperaBookmark_GOperaImage = nil;

NSString *getOperaBookmarksPath() {
	return [@"~/Library/Preferences/Opera Preferences/bookmarks.adr" stringByExpandingTildeInPath];
}

NSString *getOperaSearchesPath() {
	return [@"~/Library/Preferences/Opera Preferences/search.ini" stringByExpandingTildeInPath];
}
NSDate *qsopera_getDateOfFileLastChange(NSString *path) {
  NSError *error = nil;
  NSDictionary *result = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
	if (result)
		return (NSDate *)[result objectForKey:NSFileModificationDate];
  return nil;
}

+(NSDate *)getLastChangeDate {
  NSDate *dBookmarks = qsopera_getDateOfFileLastChange(getOperaBookmarksPath());
  NSDate *dSearches = qsopera_getDateOfFileLastChange(getOperaSearchesPath());
  if (!dBookmarks) return dSearches ?: [NSDate date];
  if (!dSearches) return dBookmarks;
  return [dBookmarks laterDate:dSearches];
}

NSString *getOperaBookmarkIconPath(NSString *iconFile) {
	return [[@"~/Library/Preferences/Opera Preferences/Icons/" stringByExpandingTildeInPath] stringByAppendingPathComponent:iconFile];
}

+(NSImage *)getOperaIcon {
	if (OperaBookmark_GOperaImage == nil)
		OperaBookmark_GOperaImage = [[[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.operasoftware.Opera"]] retain];
	return OperaBookmark_GOperaImage;
}

BOOL getTwoStringsFromAE(NSAppleEventDescriptor *returnDescriptor, NSString **stringOut1, NSString **stringOut2)
{
    if (returnDescriptor != NULL)
        if (kAENullEvent != [returnDescriptor descriptorType])
            if (typeAEList == [returnDescriptor descriptorType])
            {
				NSUInteger iCount = 0;
				while ([returnDescriptor descriptorAtIndex:(iCount + 1)] != nil)
					iCount++;
				if (iCount == 2)
				{
					*stringOut1 = [[returnDescriptor descriptorAtIndex:1] stringValue];
					*stringOut2 = [[returnDescriptor descriptorAtIndex:2] stringValue];
					return YES;
				}
            }
	return NO;
}

+(BOOL)getCurrentOperaURL:(NSString **)url andTitle:(NSString **)title {
	NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
	
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
								   @"\
								   tell application \"System Events\"\n\
								   if (number of items in (application processes where bundle identifier is \"com.operasoftware.Opera\")) = 0 then return null\n\
								   end tell\n\
								   tell application \"Opera\"\n\
								   if number of documents is 0 then return null\n\
								   return { name of front document, URL of front document }\n\
								   end tell\n\
								   "];
	
    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
    [scriptObject release];
	return getTwoStringsFromAE(returnDescriptor, url, title);
}

+(NSArray *)getCurrentOperaTabs {
	NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
	
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
								   @"\
								   tell application \"System Events\"\n\
								   if (number of items in (application processes where bundle identifier is \"com.operasoftware.Opera\")) = 0 then return null\n\
								   end tell\n\
								   set theResult to {}\n\
								   tell application \"Opera\"\n\
								   repeat with i from 1 to number of documents\n\
								   set theResult to theResult & {{name of document i, URL of document i}}\n\
								   end repeat\n\
								   end tell\n\
								   return theResult\n\
								   "];
	
    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
    [scriptObject release];
	
    if (returnDescriptor != NULL)
        if (kAENullEvent != [returnDescriptor descriptorType])
            if (typeAEList == [returnDescriptor descriptorType])
            {
				NSMutableArray *oResult = [NSMutableArray arrayWithObjects:nil];
				NSInteger i = 1;
				while ([returnDescriptor descriptorAtIndex:i] != nil)
				{
					NSString *sTitle = nil;
					NSString *sURL = nil;
					if (getTwoStringsFromAE([returnDescriptor descriptorAtIndex:i], &sTitle, &sURL))
					{
						OperaBookmark *oBookmark = [[OperaBookmark alloc] init];  
						[oBookmark setTitle:sTitle];
						[oBookmark setURL:sURL];
						[oResult addObject:oBookmark];
						[oBookmark release];
					}
					i++;
				}
				return oResult;
            }
	return nil;
}


OperaBookmark *parseBookmark(NSArray *lines) {
	OperaBookmark *oItem = [[[OperaBookmark alloc] init] autorelease];
	BOOL bHasName = NO;
	BOOL bHasURL = NO;
    for (NSString *sLine in lines)
	{
		sLine = [sLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([sLine hasPrefix:@"NAME="])
		{
			bHasName = YES;
			[oItem setTitle:[sLine substringFromIndex:5]];
		}
		else if ([sLine hasPrefix:@"URL="])
		{
			bHasURL = YES;
			[oItem setURL:[sLine substringFromIndex:4]];
		}
		else if ([sLine hasPrefix:@"SHORT NAME="])
			[oItem setKeywords:[sLine substringFromIndex:11]];
		else if ([sLine hasPrefix:@"DESCRIPTION="])
			[oItem setDescription:[sLine substringFromIndex:12]];
		else if ([sLine hasPrefix:@"ICONFILE="])
			[oItem setIcon:getOperaBookmarkIconPath([sLine substringFromIndex:9])];
	}
	return (bHasName && bHasURL) ? oItem : nil;
}
OperaBookmark *parseSearch(NSArray *lines) {
	OperaBookmark *oItem = [[[OperaBookmark alloc] init] autorelease];
	BOOL bHasName = NO;
    BOOL bUsePost = NO;
    NSString *sURL = nil;
	for (NSString *sLine in lines)
	{
		sLine = [sLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([sLine hasPrefix:@"Name="])
		{
			bHasName = YES;
			[oItem setTitle:[sLine substringFromIndex:5]];
		}
		else if ([sLine hasPrefix:@"URL="])
            sURL = [[sLine substringFromIndex:4] stringByReplacingOccurrencesOfString:@"%s" withString:@"***"];
		else if ([sLine hasPrefix:@"Key="])
			[oItem setKeywords:[sLine substringFromIndex:4]];
        else if ([sLine hasPrefix:@"Is post="]) {
            bUsePost = [[sLine substringFromIndex:8] isEqualToString:@"1"];
        }
		else if ([sLine hasPrefix:@"Deleted="])
		{
			if ([[sLine substringFromIndex:8] isEqualToString:@"1"])
				return nil;
		}
	}
    if (bHasName && sURL) {
        [oItem setURL:[(bUsePost ? @"qssp-" : @"qss-") stringByAppendingString:sURL]];
        return oItem;
    }
	return nil;
}

+(NSArray*)loadBookmarks {
	NSError *err = nil;
  NSString *sFilename = getOperaBookmarksPath();
	NSString *sBookmarks = [NSString stringWithContentsOfFile:sFilename encoding:NSUTF8StringEncoding error:&err];
	if (sBookmarks == nil || err != nil) {
    NSLog(@"[QSOpera] Error reading bookmarks from '%@': %@", sFilename, [err description] ?: @"<no NSError>");
		return nil;
  }
	NSArray *sLines = [sBookmarks componentsSeparatedByString:@"\n"];
	NSUInteger iCount = sLines.count;
	
	if (iCount < 3) return nil;
	if (![(NSString *)[sLines objectAtIndex:0] isEqualToString:@"Opera Hotlist version 2.0"])
	{
    NSLog(@"[QSOpera] Error reading bookmarks from '%@': %@", sFilename, @"Format unexpected (1).");
		return nil;
	}
	if (![(NSString *)[sLines objectAtIndex:1] isEqualToString:@"Options: encoding = utf8, version=3"])
	{
    NSLog(@"[QSOpera] Error reading bookmarks from '%@': %@", sFilename, @"Format unexpected (2).");
		return nil;
	}
	
	NSUInteger i = 1;
	BOOL bCapturing = FALSE;
	NSMutableArray *oBlock = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *oArray = [[[NSMutableArray alloc] init] autorelease];
	while (i < iCount - 1)
	{
		i++;
		NSString *sLine = (NSString *)[sLines objectAtIndex:i];
		if (sLine.length > 0)
		{
			if ([sLine hasPrefix:@"#"] || [sLine hasPrefix:@"-"])
			{
				if (bCapturing)
				{
					OperaBookmark *oItem = parseBookmark(oBlock);
					[oBlock removeAllObjects];
					if (oItem != nil)
						[oArray addObject:oItem];
				}
				bCapturing = [sLine isEqualToString:@"#URL"];
			}
			else
				if (bCapturing)
					[oBlock addObject:sLine];
		}
	}
	if (bCapturing && [oBlock count] > 0)
	{
		OperaBookmark *oItem = parseBookmark(oBlock);
		[oBlock removeAllObjects];
		if (oItem != nil)
			[oArray addObject:oItem];
	}
	return oArray;
}

+(NSArray*)loadSearches {
	NSError *err = nil;
  NSString *sFilename = getOperaSearchesPath();
	NSString *sBookmarks = [NSString stringWithContentsOfFile:sFilename encoding:NSUTF8StringEncoding error:&err];
	if (sBookmarks == nil || err != nil) {
    NSLog(@"[QSOpera] Error reading searches from '%@': %@", sFilename, [err description] ?: @"<no NSError>");
		return nil;
  }
	NSArray *sLines = [sBookmarks componentsSeparatedByString:@"\n"];
	NSUInteger iCount = sLines.count;
	
	if (iCount < 1) {
    NSLog(@"[QSOpera] Error reading searches from '%@': %@", sFilename, @"Format unexpected (3).");
    return nil;
  }
	if (![(NSString *)[sLines objectAtIndex:0] isEqualToString:@"Opera Preferences version 2.1"])
	{
    NSLog(@"[QSOpera] Error reading searches from '%@': %@", sFilename, @"Format unexpected (4).");
		return nil;
	}
	BOOL bCapturing = FALSE;
	NSMutableArray *oBlock = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *oArray = [[[NSMutableArray alloc] init] autorelease];
    for(NSString *sLine in sLines)
	{
		sLine = [sLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		if (sLine.length > 0 && ![sLine hasPrefix:@";"])
		{
			if ([sLine hasPrefix:@"["])
			{
				if (bCapturing)
				{
					OperaBookmark *oItem = parseSearch(oBlock);
					[oBlock removeAllObjects];
					if (oItem != nil)
						[oArray addObject:oItem];
				}
				bCapturing = [sLine hasPrefix:@"[Search Engine "];
			}
			else
				if (bCapturing)
					[oBlock addObject:sLine];
		}
	}
	if (bCapturing && [oBlock count] > 0)
	{
		OperaBookmark *oItem = parseSearch(oBlock);
		[oBlock removeAllObjects];
		if (oItem != nil)
			[oArray addObject:oItem];
	}
	return oArray;
}

-(NSString *)keywordPrefixedTitle {
	if (self.keywords == nil)
		return self.title;
	return [NSString stringWithFormat:@"%@ - %@", self.keywords, self.title];
}

-(NSImage *)loadIcon {
	if (self.icon != nil)
	{
		NSImage * oRes = [[[NSImage alloc] initWithContentsOfFile:self.icon] autorelease];
		if (oRes != nil) return oRes;
	}
	return [OperaBookmark getOperaIcon];
}

-(id)init {
	if ((self = [super init])) {
		_sTitle = nil;
		_sIcon = nil;
		_sURL = nil;
		_sDescription = nil;
		_sKeywords = nil;
	}
	return self;
}

- (void)dealloc
{
    self.title = nil;
    self.icon = nil;
    self.URL = nil;
    self.description = nil;
    self.keywords = nil;
    [super dealloc];
}


@end
