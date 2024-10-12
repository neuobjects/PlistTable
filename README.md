## Overview

This class was created specifically for the *Report Builder for Xcode* tutorials to allow the samples to include database-like access to the sample data. The goal was to provide basic routines to read report information without having to implement Core Data, SQLite or any other database which might add additional complexity to the tutorial. I'm not sure if I succeeded, but I tried...

### Features

- Provides read-only access to plist files within the application bundle.
- Automatically maps values from the plist to object properties. 
- Offers rudimentary support for relationships.
