//
//  QSOperaBundleSource.m
//  QSOpera
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

#import "QSOperaBundleSource.h"
#import "OperaBookmark.h"
#import "QSOpera.h"


@implementation QSOperaBundleSource

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
	return NO;
}

- (NSImage *) iconForEntry:(NSDictionary *)dict{
    return [OperaBookmark getOperaIcon];
}

- (NSArray *) getTabs{
	NSArray *oTabs = [OperaBookmark getCurrentOperaTabs];
	if (oTabs != nil)
	{
		NSMutableArray *oCurQSTabs=[NSMutableArray arrayWithCapacity:[oTabs count]];
		[QSOpera mapObjectsFrom:oTabs into:oCurQSTabs];
		return oCurQSTabs;
	}
	return nil;
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
	if (object == nil || ![[[NSBundle bundleWithPath:[object singleFilePath]] bundleIdentifier] isEqualToString:@"com.operasoftware.Opera"] )
		return NO;
    
    // Open pages
    QSObject *currentPages = [QSObject makeObjectWithIdentifier:@"QSOperaOpenPages"];
    [currentPages setName:@"Open Web Pages (Opera)"];
    [currentPages setDetails:@"URLs from all open windows and tabs"];
    [currentPages setPrimaryType:@"qs.opera.openPages"];
    [currentPages setIcon:[QSResourceManager imageNamed:@"com.operasoftware.Opera"]];
	NSArray *children = [self getTabs];
    if (children) {
        [currentPages setChildren:children];
    }
    
    // Bookmarks
    NSArray *oSearchItems = [OperaBookmark loadSearches];
	NSArray *oBookmarkItems = [OperaBookmark loadBookmarks];
	NSUInteger iCount = (oSearchItems != nil ? [oSearchItems count] : 0) + (oBookmarkItems != nil ? [oBookmarkItems count] : 0);
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:iCount];
	if (oBookmarkItems != nil)
		[QSOpera mapObjectsFrom:oBookmarkItems into:objects];
	if (oSearchItems != nil)
		[QSOpera mapObjectsFrom:oSearchItems into:objects];
    
    QSObject *group = [QSObject objectWithName:@"Bookmarks"];
	//NSLog(@"title %@", title);
	[group setIdentifier:@"qs.opera.Bookmarks"];
	[group setChildren:objects];
	[group setPrimaryType:@"qs.opera.bookmarkGroup"];
	[group setObject:@"" forMeta:kQSObjectDefaultAction];
    [group setObject:objects forType:QSURLType];
    [object setChildren:[NSArray arrayWithObjects:currentPages,group,nil]];
    return YES;
}

- (void)setQuickIconForObject:(QSObject *)object {
    [object setIcon:[QSResourceManager imageNamed:@"com.operasoftware.Opera"]];
}


@end
