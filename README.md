# CrudRouter

CrudRouter makes it as simple as possible to set up CRUD (Create, Read, Update, Delete) routes for any `Model`.

## Installation
Within your Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/twof/VaporCRUDRouter.git", from: "1.0.0")
]
```
and

```swift
targets: [
    .target(name: "App", dependencies: ["CrudRouter"]),
]
```

## Usage
Within your router setup (`routes.swift` in the default Vapor API template)
```swift
router.crud(register: Todo.self)
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
router.crud(register: SchoolTeacher.self)
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
router.crud("account", register: User.self)
```
results in

```
GET /account
GET /account/:id
POST /account
PUT /account/:id
DELETE /account/:id
```

#### Nested Relations
Say you had a model `User`, which was the parent of another model `Todo`. If you'd like routes to expose all `Todo`s that belong to a specific `User`, you can do something like this.

```swift
try router.crud(register: User.self) { controller in
    try controller.crud(children: \.todos)
}
```

results in

```
GET /user
GET /user/:id
POST /user
PUT /user/:id
DELETE /user/:id

GET/user/:id/todo
GET /user/:id/todo/:id
POST/user/:id/todo
PUT/user/:id/todo/:id
DELETE/user/:id/todo/:id
```

within the supplied closure, you can also expose routes for related `Parent`s and `Sibling`s

```swift
try controller.crud(children: \.todos)
try controller.crud(parent: \.todos)
try controller.crud(siblings: \.todos)
```

### Future features
- query parameter support
- PATCH support
- more fine grained response statuses
- recursive relation configuration
- automatically expose relations (blocked by lack of Swift reflection support)
- documentation for all public functions
- generate models and rest routes via console command
- enum based route selection
