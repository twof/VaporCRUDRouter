# CrudRouter

CrudRouter makes it as simple as possible to set up CRUD (Create, Read, Update, Delete) routes for any `Model`.

## Usage
Within your router setup (`routes.swift` in the default Vapor API template)
```swift
router.crudRegister(for: Todo.self)
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

Generated paths default to using lower snake case so for example, if you were to do

```swift
router.crudRegister(for: SchoolTeacher.self)
```
you'd get routes like

```
GET /school_teacher
GET /school_teacher/:id
POST /school_teacher
PUT /school_teacher/:id
DELETE /school_teacher/:id
```

#### Path Configuration
If you'd like to supply your own path rather than using the name of the supplied model, you can also do that

```swift
router.crudRegister("account", for: User.self)
```
results in

```
GET /account
GET /account/:id
POST /account
PUT /account/:id
DELETE /account/:id
```

### Future features
- query parameter support
- PATCH support
- more fine grained response statuses
- embeded fields ex. `/user/1/todo` to get all `todo`s belonging to user with id 1
