# CrudRouter

CrudRouter makes it as simple as possible to set up CRUD (Create, Read, Update, Delete) routes for any `Model`.

## Usage:
Within your router setup (`routes.swift` in the default Vapor API template)
```swift
router.crudRegister("todo", for: Todo.self)
```
That's it!

That one line gets you the following routes.

```
GET /todo
GET /todo/:id
POST /todo
PUT /todo/:id
DELETE /todo/:id
```

### Future features
- query parameter support
- PATCH support
- more fine grained response statuses
- embeded fields ex. `/user/1/todo` to get all `todo`s belonging to user with id 1
