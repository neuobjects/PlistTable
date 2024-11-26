//
//  PlistTable.m
//
//  Created by Brian Lazarz on 9/8/23.
//

#import "PlistTable.h"

@interface PlistTable()

@property (nonatomic, strong) NSArray<NSDictionary *> *rawContents;//dictionary entries of records
@property (nonatomic, strong) NSArray *rows;
@property (nonatomic, strong) Class classType;
@property (nonatomic, copy) NSString *primaryKeyPropertyName;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray *> *indexes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *relationships;

@end

@implementation PlistTable

/*!
 @brief Instantiate a PlistTable instance
 @discussion This method will attempt to load an array of objects from a plist file in the application bundle. Each entry of the array is a dictionary of property values that correspond to the property names in the class we'll be loading.
 @param classType The type of class the objects represent.
 @param keyPropertyName The primary key for accessing a unique record.
 */
+(instancetype) plistTableForClass:(Class) classType
                primaryKeyProperty:(NSString *) keyPropertyName
{
  //NOTE: this doesn't work with swift the classType is "ReportBuilderDemo_iOS_Swift.ELEmployee"
  PlistTable *plistTable = [[PlistTable alloc] init];
  plistTable.classType = classType;
  plistTable.primaryKeyPropertyName = keyPropertyName;
  
  plistTable.indexes = [NSMutableDictionary<NSString *, NSArray *> dictionary];
  plistTable.relationships = [NSMutableDictionary<NSString *, NSDictionary *> dictionary];
  
  NSString *fullResourceName = [classType description];
  NSArray<NSString *> *components = [fullResourceName componentsSeparatedByString:@"."];
  NSString *resourceName = [components lastObject];
  NSString *dataPath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"plist"];
  //NSLog(@"dataPath:%@", dataPath);
  plistTable.rawContents = [NSArray arrayWithContentsOfFile:dataPath];
  if ([plistTable.rawContents count] > 0)
  {
    NSMutableArray *rows = [NSMutableArray array];
    for (NSDictionary *dict in plistTable.rawContents)
    {
      NSObject *object = [plistTable mapRow:dict];
      [rows addObject:object];
    }
    plistTable.rows = [NSArray arrayWithArray:rows];
  }
  return plistTable;
}
/*!
 @brief Instantiate a PlistTable instance
 @discussion This method will attempt to load an array of objects from a plist file in the application bundle. Each entry of the array is a dictionary of property values that correspond to the property names in the class we'll be loading.
 @param resourceName This is the name of the plist file in the bundle. A resourceName of 'Address' will attempt to load the array values from Addresses.plist.
 @param classType The type of class the objects represent.
 @param keyPropertyName The primary key for accessing a unique record.
 */
+(instancetype) plistTableWithBundleResourceName:(NSString *) resourceName
                                        forClass:(Class) classType
                              primaryKeyProperty:(NSString *) keyPropertyName
{
  PlistTable *plistTable = [[PlistTable alloc] init];
  plistTable.classType = classType;
  plistTable.primaryKeyPropertyName = keyPropertyName;
  
  plistTable.indexes = [NSMutableDictionary<NSString *, NSArray *> dictionary];
  plistTable.relationships = [NSMutableDictionary<NSString *, NSDictionary *> dictionary];
  
  NSString *dataPath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"plist"];
  //NSLog(@"dataPath:%@", dataPath);
  plistTable.rawContents = [NSArray arrayWithContentsOfFile:dataPath];
  if ([plistTable.rawContents count] > 0)
  {
    NSMutableArray *rows = [NSMutableArray array];
    for (NSDictionary *dict in plistTable.rawContents)
    {
      NSObject *object = [plistTable mapRow:dict];
      [rows addObject:object];
    }
    plistTable.rows = [NSArray arrayWithArray:rows];
  }
  return plistTable;
}

/*!
 @brief Maps a value from the dictionary to the model
 @discussion This method maps a value from the dictionary to the object and returns an instance of the object.
 @param dict The dictionary of values to map to the object.
 @return An instance of the object
 */
-(nonnull NSObject *) mapRow:(NSDictionary *) dict
{
  NSArray *propertyNames = [dict allKeys];
  NSObject *object = [[self.classType alloc] init];
  for (NSString *propertyName in propertyNames)
  {
    id value = [dict valueForKey:propertyName];
    [object setValue:value forKey:propertyName];
  }
  return object;
}


#pragma mark - retrieving data
/*!
 @brief This routine returns an array of all the values in the array.
 @return All rows in the array.
 */
-(NSArray *) findAll
{
  return self.rows;
}

/*!
 @brief Return an array of objects that match the predicate.
 @return An array of values matching the predicate.
 */
-(NSArray *) findAllUsingPredicate:(NSPredicate *) predicate
{
  NSArray *result = nil;
  result = [self.rows filteredArrayUsingPredicate:predicate];
  return result;
}

/*!
 @brief Return an array of objects that match the predicate.
 @param indexName The name of the index to sort the results by.
 @return An array of values matching the predicate.
 */
-(NSArray *) findAllUsingPredicate:(NSPredicate *) predicate
                sortedByIndexName:(NSString *) indexName
{
  NSArray *result = nil;
  NSArray *filteredRows = [self.rows filteredArrayUsingPredicate:predicate];
  NSArray *sortDescriptors = [self.indexes objectForKey:indexName];
  if (sortDescriptors)
  {
    result = [filteredRows sortedArrayUsingDescriptors:sortDescriptors];
  }
  return result;
}

/*!
 @brief Return an array of objects using the given index name.
 @param indexName The name of the index to sort the results by.
 */
-(NSArray *) findAllUsingIndexName:(NSString *) indexName
{
  NSArray *result = nil;
  NSArray *sortDescriptors = [self.indexes objectForKey:indexName];
  if (sortDescriptors)
  {
    result = [self.rows sortedArrayUsingDescriptors:sortDescriptors];
  }
  return result;
}

/*!
 @brief Returns a single object for the given key value.
 @discussion Use this method when you're expecting only one value for the key value. If more than one object matches the key value, the first object will be returned.
 @param keyValue The value of the key we're looking for.
 */
-(NSObject *) findByPrimaryKeyValue:(NSObject *) keyValue
{
  NSObject *result = nil;
  //we need to use %K to indicate it's a keypath, %@ won't work
  NSPredicate *selectByKeyPredicate = [NSPredicate predicateWithFormat:@"%K == %@", self.primaryKeyPropertyName, keyValue];
  NSArray *rows = [self.rows filteredArrayUsingPredicate:selectByKeyPredicate];
  if (rows)
    result = [rows firstObject];
  return result;
}

#pragma mark - index support
/*!
 @brief Adds an index with a given key name.
 @discussion Use this method to add simple, single-key indexes to the object.
 @param indexName The name of the index.
 @param keyName The name of the key the index will use.
 @param ascending Sort the results for this index in ascending order?
 */
-(void) addIndexNamed:(NSString *) indexName
               forKey:(NSString *) keyName
            ascending:(BOOL) ascending
{
  NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:keyName ascending:ascending];
  NSArray *descriptors = [NSArray arrayWithObject:sort];
  [self.indexes setValue:descriptors forKey:indexName];
}

/*!
 @brief Adds an indes using an array of of sort descriptors
 @param indexName The name of the index.
 @param descriptors An array of sort descriptors used to sort the results.
 */
-(void) addIndexNamed:(NSString *) indexName
      sortDescriptors:(NSArray<NSSortDescriptor *> *) descriptors
{
  [self.indexes setValue:descriptors forKey:indexName];
}

#pragma mark - basic relationship support

#define KEY_ARRAYDAO @"DetailTable"
#define KEY_PREDICATE @"Predicate"
#define KEY_HEADER @"HeaderProperty"
#define KEY_DETAIL @"DetailProperty"
/*!
 @brief Add a relationship to the object.
 @param name The name of the relationship.
 @param detailTable The instance of the PlistTable to use for for the details.
 @param from The property name in this object that will be used to join to the detailTable.
 @param to The property name in the detailTable used for the join.
 */
-(void) addRelationshipNamed:(NSString *) name
                  toPlistTable:(PlistTable *) detailTable
                     fromKey:(NSString *) from
                       toKey:(NSString *) to
{
  //add an index to the detail dao so we can grab the values by our primary key. Relationships assume the primary key in the header exists as a property in the detail.
  [detailTable addIndexNamed:name forKey:self.primaryKeyPropertyName ascending:YES];
  //Create a dictionary of the values we'll need when we retrieve the details...
  NSDictionary *valueDictionary = [NSDictionary dictionaryWithObjectsAndKeys:detailTable, KEY_ARRAYDAO, from, KEY_HEADER, to, KEY_DETAIL, nil];
  [self.relationships setObject:valueDictionary forKey:name];
}

-(NSArray *) findAllRelatedObjectsFor:(NSObject *) object
                   usingRelationship:(NSString *) name
{
  NSArray *result = nil;
  NSDictionary *relationshipDictionary = [self.relationships objectForKey:name];
  if (relationshipDictionary)
  {
    PlistTable *detailTable = [relationshipDictionary objectForKey:KEY_ARRAYDAO];
    NSString *headerProperty = [relationshipDictionary objectForKey:KEY_HEADER];
    NSString *detailProperty = [relationshipDictionary objectForKey:KEY_DETAIL];

    //grab the primary key value for this object
    NSString *toKeyValue = [object valueForKey:headerProperty];
    //select by the join fields we'll sort it by the datail dao primary key
    NSPredicate *detailPredicate = [NSPredicate predicateWithFormat:@"%K == %@", detailProperty, toKeyValue];//this needs to be the value "invoiceId = 2"
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:detailTable.primaryKeyPropertyName ascending:YES];

    //grab all the detail rows
    NSArray *detailRows = [detailTable findAll];//UsingIndexName:name];
    //filter by the join
    result = [[detailRows filteredArrayUsingPredicate:detailPredicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  }
  else
  {
    NSLog(@"index %@ not found", name);
  }
  return result;
}

/*!
 @brief Find all the records that have a given property value
 @discussion This returns a list
 @param keyValue The value of the property we're looking for
 @param property The property name to match against
 @return An array of record that have a property value that matches the given `keyValue`. The array will be sorted by the primary key;
 */
-(NSArray *) findAllByValue:(NSObject *) keyValue
                         forProperty:(NSString *) property
{
  NSArray *result = nil;
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", property, keyValue];//this needs to be the value "invoiceId = 2"
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:self.primaryKeyPropertyName ascending:YES];
  result = (NSArray *)[[self.rows filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  return result;
}

@end
