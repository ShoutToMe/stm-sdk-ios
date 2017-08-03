---
layout: home
---

# Shout to Me User

The SDK provides a `currentUser` property that can be used to access information about the user.

Get User handle:

```objc
[STM currentUser].strHandle
```

## Updating User Properties

To update the user's properties, call the `setProperties:withCompletionHandler:` method on the User service.  The
parameter object for the method call is a `SetUserPropertiesInput` object and has the following fields available for
update:

```objc
@interface SetUserPropertiesInput : NSObject

@property (nonatomic, nullable) NSString *email;
@property (nonatomic, nullable) NSString *handle;
@property (nonatomic, nullable) NSString *phoneNumber;

//...

@end
```

Pass `nil` or an empty string to remove any properties.  If there were no errors, the completion handler will return an
STMUser object which will contain the updated user info.

```objc
SetUserPropertiesInput *setUserPropertiesInput = [SetUserPropertiesInput new];
[setUserPropertiesInput setHandle:self.handleTextField.text];

// Delete properties with nil or an empty string
[setUserPropertiesInput setEmail:@""];
[setUserPropertiesInput setPhoneNumber:nil];

[[STM user] setProperties:setUserPropertiesInput withCompletionHandler:^(NSError *error, id obj) {
    if (error) {
        NSLog(@"Error: %@", [error userInfo]);
    } else {
        NSLog(@"Updated user handle!");
        STMUser *user = (STMUser *)obj;
        NSLog(@"%@", user);
    }
}];
```
