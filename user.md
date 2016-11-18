---
layout: home
---

# Shout to Me User

The SDK provides a `currentUser` property that can be used to access information about the user.

Get User handle:

```objc
[STM currentUser].strHandle
```

Update User handle:

```objc
[[STM signIn] setHandle:@"newHandle" withCompletionHandler:^(NSError *error) {
    if (error) {
        // error happened
    } else {
        // user handle was updated
    }
}
```

Date the User last read their Messages:

```objc
[STM currentUser].dateLastReadMessages
```
