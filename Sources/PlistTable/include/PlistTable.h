//
//  PlistTable.h
//
//  Created by Brian Lazarz on 9/8/23.
//
//  This class allows us to read database information from plist files.
//  In order for this to work with Swift classes, the @objc attribute needs to be assigned to the properties
//  Example:
//           @objc var name: String

#import <Foundation/Foundation.h>


@interface PlistTable : NSObject

NS_ASSUME_NONNULL_BEGIN
+(instancetype) plistTableWithBundleResourceName:(NSString *) resourceName
                                        forClass:(Class) classType
                              primaryKeyProperty:(NSString *) keyPropertyName;
+(instancetype) plistTableForClass:(Class) classType
                primaryKeyProperty:(NSString *) keyPropertyName;

-(void) addIndexNamed:(NSString *) indexName
               forKey:(NSString *) keyName
            ascending:(BOOL) ascending;
-(void) addIndexNamed:(NSString *) indexName
      sortDescriptors:(NSArray<NSSortDescriptor *> *) descriptors;

-(void) addRelationshipNamed:(NSString *) name
                toPlistTable:(PlistTable *) detailTable
                     fromKey:(NSString *) from
                       toKey:(NSString *) to;
NS_ASSUME_NONNULL_END
-(nullable NSArray *) findAll;
-(nullable NSArray *) findAllUsingPredicate:(NSPredicate * _Nonnull) predicate;
-(nullable NSArray *) findAllUsingPredicate:(NSPredicate * _Nonnull) predicate
                          sortedByIndexName:(NSString * _Nonnull) indexName;
-(nullable NSArray *) findAllUsingIndexName:(NSString * _Nonnull) indexName;
-(nullable NSObject *) findByPrimaryKeyValue:(NSObject * _Nonnull) keyValue;
-(nullable NSArray *) findAllByValue:(NSObject * _Nonnull) keyValue
                         forProperty:(NSString * _Nonnull) property;

-(nullable NSArray *) findAllRelatedObjectsFor:(NSObject * _Nonnull) object
                             usingRelationship:(NSString * _Nonnull) name;

@end
