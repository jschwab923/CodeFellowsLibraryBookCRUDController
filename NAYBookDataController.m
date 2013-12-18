//
//  NAYBookDataController.m
//  CodeFellowsLibrary
//
//  Created by Jeff Schwab on 12/17/13.
//  Copyright (c) 2013 Jeff Schwab. All rights reserved.
//

#import "NAYBookDataController.h"

const NSString *_databaseName = @"Shelves";

@interface NAYBookDataController ()

{
    sqlite3 *_database;
    NSString *_databasePath;
    NSString *_tableName;
}
@end

@implementation NAYBookDataController

- (void)createTableWithName:(NSString *)name
{
    _tableName = name;
    _database = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    _databasePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.db", _databaseName]];
    
    if (![fileManager fileExistsAtPath:_databasePath]) {
        if (![fileManager createFileAtPath:_databasePath contents:nil attributes:nil]) {
            NSLog(@"Error. Database file unable to be created");
        } else {
            if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
                NSString *sqlStatementFormatter =
                    [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY, title TEXT, author TEXT)", _tableName];
                
                const char *sqlStatement = [sqlStatementFormatter UTF8String];
                char *errMsg;
                
                if (sqlite3_exec(_database, sqlStatement, NULL, NULL, &errMsg) != SQLITE_OK) {
                    NSLog(@"Error creating table, Error: '%s'", errMsg);
                }
                sqlite3_close(_database);
            } else {
                NSLog(@"Error. SQLITE File could not be opened");
            }
        }
    }
}

- (NSArray *)getAllBooks
{
    NSMutableArray *booksFromTable = [NSMutableArray array];
    
    sqlite3_open([_databasePath UTF8String], &_database);
    
    if (!_database) {
        NSLog(@"Error opening database");
        return nil;
    }
    
    sqlite3_stmt *getAllStatement;
    const char *prepareStatement = [[NSString stringWithFormat:@"SELECT id, title, author FROM %@", _tableName] UTF8String];
    if (sqlite3_prepare_v2(_database, prepareStatement, -1, &getAllStatement, nil) != SQLITE_OK) {
        NSLog(@"Error. SQLITE Failed to prepare statement with error: '%s'", sqlite3_errmsg(_database));
        return nil;
    }
    
    while(sqlite3_step(getAllStatement) == SQLITE_ROW) {
        NSInteger bookId = sqlite3_column_int(getAllStatement, 0);
        NSString *title = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(getAllStatement, 1)];
        NSString *author = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(getAllStatement, 2)];
        
        NAYBook *book = [[NAYBook alloc] initWithTitle:title author:author];
        book.id = bookId;
        [booksFromTable addObject:book];
    }
    
    sqlite3_finalize(getAllStatement);
    sqlite3_close(_database);
    
    return [booksFromTable copy];
}

- (void)addBook:(NAYBook *)book
{
    if (sqlite3_open([_databasePath UTF8String], &_database) != SQLITE_OK) {
        NSLog(@"Error opening database");
    } else {
        sqlite3_stmt *queryStatement;
        const char *addStatement = [[NSString stringWithFormat:
                                     @"INSERT INTO %@ (id, title, author) VALUES('%i', '%@', '%@')", _tableName, (int)book.id, book.title, book.author] UTF8String];
        
        if (sqlite3_prepare_v2(_database, addStatement, -1, &queryStatement, NULL) != SQLITE_OK) {
            NSLog(@"Error preparing statment. Error: '%s'", sqlite3_errmsg(_database));
            sqlite3_close(_database);
            return;
        }
        
        if (sqlite3_step(queryStatement) == SQLITE_ERROR) {
            NSLog(@"Error accessing database. Error: '%s'", sqlite3_errmsg(_database));
            sqlite3_close(_database);
            return;
        }
        sqlite3_finalize(queryStatement);
        sqlite3_close(_database);
    }
}

- (void)addArrayOfBooks:(NSArray *)books
{
    sqlite3_open([_databasePath UTF8String], &_database);
    
    if (!_database) {
        NSLog(@"Error opening database");
    } else {
        for (NAYBook *book in books) {
            sqlite3_stmt *queryStatement;
            const char *addStatement = [[NSString stringWithFormat:@"INSERT INTO %@ (id, title, author) VALUES('%i', '%@', '%@')", _tableName, (int)book.id, book.title, book.author] UTF8String];
            if (sqlite3_prepare_v2(_database, addStatement, -1, &queryStatement, nil) != SQLITE_OK) {
                NSLog(@"Error preparing statment. Error: '%s'", sqlite3_errmsg(_database));
                sqlite3_close(_database);
                return;
            }
            
            if (sqlite3_step(queryStatement) == SQLITE_ERROR) {
                NSLog(@"Error accessing database. Error: '%s'", sqlite3_errmsg(_database));
                sqlite3_close(_database);
                return;
            }
            sqlite3_finalize(queryStatement);
        }
        sqlite3_close(_database);
    }
}

- (void)updateBook:(NAYBook *)book
{
    sqlite3_open([_databasePath UTF8String], &_database);
    
    if (!_database) {
        NSLog(@"Error opening database");
    } else {
        const char *updateStatement = [[NSString stringWithFormat:@"UPDATE %@ SET title='%@', author='%@' WHERE id='%i'", _tableName, book.title, book.author, (int)book.id] UTF8String];
        [self sqlQueryWithStatement:updateStatement];
        sqlite3_close(_database);
    }
}

- (void)deleteBook:(NAYBook *)book
{
    sqlite3_open([_databasePath UTF8String], &_database);
    
    if (!_database) {
        NSLog(@"Error opening database");
        return;
    }
    
    const char *deleteStatement = [[NSString stringWithFormat:@"DELETE FROM %@ WHERE id='%i'", _tableName, (int)book.id] UTF8String];
    
    if (sqlite3_exec(_database, deleteStatement, NULL, NULL, NULL) == SQLITE_ABORT) {
        NSLog(@"Error deleting from database: Error: '%s'", sqlite3_errmsg(_database));
        return;
    }
    
    sqlite3_close(_database);
}

- (void)sqlQueryWithStatement:(const char *)statement
{
    sqlite3_stmt *queryStatement;
    if (sqlite3_prepare_v2(_database, statement, -1, &queryStatement, nil) != SQLITE_OK) {
        NSLog(@"Error preparing statment. Error: '%s'", sqlite3_errmsg(_database));
        sqlite3_close(_database);
        return;
    }
    
    if (sqlite3_step(queryStatement) == SQLITE_ERROR) {
        NSLog(@"Error accessing database. Error: '%s'", sqlite3_errmsg(_database));
        sqlite3_close(_database);
        return;
    }
    
    sqlite3_finalize(queryStatement);
}

@end
