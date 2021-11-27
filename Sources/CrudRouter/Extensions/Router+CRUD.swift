import Vapor
import Fluent

public extension RoutesBuilder {

    /// Creates CRUD endpoints for the supplied `type`.
    ///
    /// By default, the routes will be created that
    /// - Get an individual model with the provided ID
    /// - Get all models
    /// - Create a new model
    /// - Update a model with the provided ID
    /// - Delete a module with the provided ID
    ///
    /// For example
    ///    ```swift
    ///    router.crud(register: Todo.self)
    ///    ```
    /// Will create the following routes.
    ///
    ///    ```
    ///    GET     /todo       // returns all Todos
    ///    GET     /todo/:id   // returns the Todo with :id
    ///    POST    /todo       // create new Todo with provided body
    ///    PUT     /todo/:id   // update Todo with :id
    ///    DELETE  /todo/:id   // delete Todo with :id
    ///    ```
    ///
    ///    Generated paths default to using lower snake case so for example, if you were to do
    ///
    ///    ```swift
    ///    router.crud(register: SchoolTeacher.self)
    ///    ```
    ///    you'd get routes like
    ///
    ///    ```
    ///    GET     /school_teacher
    ///    GET     /school_teacher/:id
    ///    POST    /school_teacher
    ///    PUT     /school_teacher/:id
    ///    DELETE  /school_teacher/:id
    ///    ```
    ///
    /// - Parameter path: Overrides the path instead of using the default path string.
    /// - Parameter type: Model to generate endpoints for
    /// - Parameter either: Users can select a subset of endpoints to generate with `.only()` or exclude a subset of endpoints with `.except()`
    /// - Parameter relationConfiguration: Closure that can be used to configure endpoints for children, parents or siblings of `type`.
    ///
    ///     For example
    ///        ```
    ///        app.crud("foo", register: Planet.self) { router in
    ///            router.crud(at: "foo", siblings: \.$tags)
    ///            router.crud(at: "foo", parent: \.$galaxy)
    ///        }
    ///
    ///        app.crud("foo", register: Galaxy.self, .only([.delete])) { router in
    ///            router.crud(at: "foo", children: \.$planets)
    ///        }
    ///        ```
    func crud<ModelType: Model & Content>(
        _ path: [PathComponent]=[],
        register type: ModelType.Type,
        _ either: OnlyExceptEither<RouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudController<ModelType>) -> ())?=nil
    ) {
        let controller: CrudController<ModelType>

        switch either {
        case .only(let methods):
            controller = CrudController(
                path: path,
                router: self,
                activeMethods: Set(methods)
            )
        case .except(let methods):
            let allMethods = Set(RouterMethod.allCases)
            controller = CrudController(
                path: path,
                router: self,
                activeMethods: allMethods.subtracting(Set(methods))
            )
        }

        do { try controller.boot(routes: self) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }

    /// Creates CRUD endpoints for the suplied `type`.
    ///
    /// By default, the routes will be created that
    /// - Get an individual model with the provided ID
    /// - Get all models
    /// - Create a new model
    /// - Update a model with the provided ID
    /// - Delete a module with the provided ID
    ///
    /// For example
    ///    ```swift
    ///    router.crud(register: Todo.self)
    ///    ```
    /// Will create the following routes.
    ///
    ///    ```
    ///    GET     /todo       // returns all Todos
    ///    GET     /todo/:id   // returns the Todo with :id
    ///    POST    /todo       // create new Todo with provided body
    ///    PUT     /todo/:id   // update Todo with :id
    ///    DELETE  /todo/:id   // delete Todo with :id
    ///    ```
    ///
    ///    Generated paths default to using lower snake case so for example, if you were to do
    ///
    ///    ```swift
    ///    router.crud(register: SchoolTeacher.self)
    ///    ```
    ///    you'd get routes like
    ///
    ///    ```
    ///    GET     /school_teacher
    ///    GET     /school_teacher/:id
    ///    POST    /school_teacher
    ///    PUT     /school_teacher/:id
    ///    DELETE  /school_teacher/:id
    ///    ```
    ///
    /// - Parameter path: Overrides the path instead of using the default path string.
    /// - Parameter type: Model to generate endpoints for
    /// - Parameter either: Users can select a subset of endpoints to generate with `.only()` or exclude a subset of endpoints with `.except()`
    /// - Parameter relationConfiguration: Closure that can be used to configure endpoints for children, parents or siblings of `type`.
    ///
    ///     For example
    ///        ```
    ///        app.crud("foo", register: Planet.self) { router in
    ///            router.crud(at: "foo", siblings: \.$tags)
    ///            router.crud(at: "foo", parent: \.$galaxy)
    ///        }
    ///
    ///        app.crud("foo", register: Galaxy.self, .only([.delete])) { router in
    ///            router.crud(at: "foo", children: \.$planets)
    ///        }
    ///        ```
    func crud<ModelType: Model & Content>(
        _ path: PathComponent...,
        register type: ModelType.Type,
        _ either: OnlyExceptEither<RouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudController<ModelType>) -> ())?=nil
    ) {
        crud(path, register: type, either, relationConfiguration: relationConfiguration)
    }
}
