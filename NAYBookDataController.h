//
//  NAYBookDataController.h
//  CodeFellowsLibrary
//
//  Created by Jeff Schwab on 12/17/13.
//  Copyright (c) 2013 Jeff Schwab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NAYBook.h"
#import <sqlite3.h>

@interface NAYBookDataController : NSObject

- (void)createTableWithName:(NSString *)name;
- (NSArray *)getAllBooks;
- (void)addBook:(NAYBook *)book;
- (void)addArrayOfBooks:(NSArray *)books;
- (void)updateBook:(NAYBook *)book;
- (void)deleteBook:(NAYBook *)book;

@end
