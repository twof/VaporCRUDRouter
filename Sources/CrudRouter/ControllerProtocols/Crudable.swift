import Vapor
import Fluent

public protocol Crudable {
    associatedtype OriginType: Model, Content
    associatedtype TargetType: Model, Content where TargetType.IDValue: LosslessStringConvertible

    var path: [PathComponent] { get }
    var router: RoutesBuilder { get }

    func crud<ParentType>(
        at path: PathComponent...,
        parent relation: KeyPath<TargetType, ParentProperty<TargetType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod>,
        relationConfiguration: ((CrudParentController<TargetType, ParentType>) -> Void)?
    ) where
        ParentType: Model & Content

    func crud<ParentType>(
        at path: [PathComponent],
        parent relation: KeyPath<TargetType, ParentProperty<TargetType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod>,
        relationConfiguration: ((CrudParentController<TargetType, ParentType>) -> Void)?
    ) where
        ParentType: Model & Content

    func crud<ChildType>(
        at path: PathComponent...,
        children relation: KeyPath<TargetType, ChildrenProperty<TargetType, ChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod>,
        relationConfiguration: ((CrudChildrenController<TargetType, ChildType>) -> Void)?
    ) where
        ChildType: Model & Content

    func crud<ChildType>(
        at path: [PathComponent],
        children relation: KeyPath<TargetType, ChildrenProperty<TargetType, ChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod>,
        relationConfiguration: ((CrudChildrenController<TargetType, ChildType>) -> Void)?
    ) where
        ChildType: Model & Content

    func crud<SiblingType, ThroughType>(
        at path: PathComponent...,
        siblings relation: KeyPath<TargetType, SiblingsProperty<TargetType, SiblingType, ThroughType>>,
        _ either: OnlyExceptEither<SiblingRouterMethod>,
        relationConfiguration: ((CrudSiblingsController<TargetType, SiblingType, ThroughType>) -> Void)?
    ) where
        SiblingType: Content,
        ThroughType: Model

    func crud<SiblingType, ThroughType>(
        at path: [PathComponent],
        siblings relation: KeyPath<TargetType, SiblingsProperty<TargetType, SiblingType, ThroughType>>,
        _ either: OnlyExceptEither<SiblingRouterMethod>,
        relationConfiguration: ((CrudSiblingsController<TargetType, SiblingType, ThroughType>) -> Void)?
    ) where
        SiblingType: Content,
        ThroughType: Model
}

extension Crudable {
    /// Creates CRUD endpoints for the suplied `relation`.
    ///
    /// By default, the routes will be created that
    /// - Get the parent
    /// - Update the parent
    ///
    /// For example
    ///    ```swift
    ///    router.crud(register: Todo.self) { todoRouter in
    ///        todoRouter.crud("owner", parent: \.$owner)
    ///    }
    ///    ```
    /// Will create the following routes.
    ///
    ///    ```
    ///    GET     /todo/:id/owner
    ///    PUT     /todo/:id/owner
    ///    ```
    ///
    /// - Parameter path: Overrides the path instead of using the default path string.
    /// - Parameter relation: Parent relation on the router's model type.
    /// - Parameter either: Users can select a subset of endpoints to generate with `.only()` or exclude a subset of endpoints with `.except()`
    /// - Parameter relationConfiguration: Closure that can be used to configure endpoints for children, parents or siblings of `type`.
    ///
    ///     For example
    ///        ```
    ///        app.crud("foo", register: Planet.self) { router in
    ///            router.crud(at: "foo", parent: \.$galaxy) { galaxyRouter in
    ///                galaxyRouter.crud(children: \.$planets)
    ///            }
    ///        }
    ///        ```
    public func crud<ParentType>(
        at path: [PathComponent],
        parent relation: KeyPath<TargetType, ParentProperty<TargetType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod> = .only(ParentRouterMethod.allCases),
        relationConfiguration: ((CrudParentController<TargetType, ParentType>) -> Void)?=nil
    ) where
        ParentType: Model & Content
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: ParentType.self)

        let fullPath = baseIdPath + adjustedPath

        let controller: CrudParentController<TargetType, ParentType>

        switch either {
        case .only(let methods):
            controller = CrudParentController(
                relation: relation,
                path: fullPath,
                router: self.router,
                activeMethods: Set(methods)
            )
        case .except(let methods):
            let allMethods = Set(ParentRouterMethod.allCases)
            controller = CrudParentController(
                relation: relation,
                path: fullPath,
                router: self.router,
                activeMethods: allMethods.subtracting(Set(methods))
            )
        }

        do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }

    /// Creates CRUD endpoints for the suplied `relation`.
    ///
    /// By default, the routes will be created that
    /// - Get the parent
    /// - Update the parent
    ///
    /// For example
    ///    ```swift
    ///    router.crud(register: Todo.self) { todoRouter in
    ///        todoRouter.crud("owner", parent: \.$owner)
    ///    }
    ///    ```
    /// Will create the following routes.
    ///
    ///    ```
    ///    GET     /todo/:id/owner
    ///    PUT     /todo/:id/owner
    ///    ```
    ///
    /// - Parameter path: Overrides the path instead of using the default path string.
    /// - Parameter relation: Parent relation on the router's model type.
    /// - Parameter either: Users can select a subset of endpoints to generate with `.only()` or exclude a subset of endpoints with `.except()`
    /// - Parameter relationConfiguration: Closure that can be used to configure endpoints for children, parents or siblings of `type`.
    ///
    ///     For example
    ///        ```
    ///        app.crud("foo", register: Planet.self) { router in
    ///            router.crud(at: "foo", parent: \.$galaxy) { galaxyRouter in
    ///                galaxyRouter.crud(children: \.$planets)
    ///            }
    ///        }
    ///        ```
    public func crud<ParentType>(
        at path: PathComponent...,
        parent relation: KeyPath<TargetType, ParentProperty<TargetType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod> = .only(ParentRouterMethod.allCases),
        relationConfiguration: ((CrudParentController<TargetType, ParentType>) -> Void)?=nil
    ) where
        ParentType: Model & Content
    {
        crud(at: path, parent: relation, either, relationConfiguration: relationConfiguration)
    }

    /// Creates CRUD endpoints for the suplied `relation`.
    ///
    /// By default, the routes will be created that
    ///
    /// - Get an individual child with the provided ID
    /// - Get all children
    /// - Create a new child
    /// - Update a child with the provided ID
    /// - Delete a child with the provided ID
    ///
    /// For example
    ///    ```swift
    ///    router.crud(register: Todo.self) { todoRouter in
    ///        todoRouter.crud("subtasks", children: \.$subtasks)
    ///    }
    ///    ```
    /// Will create the following routes.
    ///
    ///    ```
    ///    GET     /todo/:id/subtasks
    ///    GET     /todo/:id/subtasks/:id
    ///    POST    /todo/:id/subtasks
    ///    PUT     /todo/:id/subtasks/:id
    ///    DELETE  /todo/:id/subtasks/:id
    ///    ```
    ///
    /// - Parameter path: Overrides the path instead of using the default path string.
    /// - Parameter relation: Children relation on the router's model type.
    /// - Parameter either: Users can select a subset of endpoints to generate with `.only()` or exclude a subset of endpoints with `.except()`
    /// - Parameter relationConfiguration: Closure that can be used to configure endpoints for children, parents or siblings of `type`.
    ///
    ///     For example
    ///        ```
    ///        app.crud("foo", register: Galaxy.self) { router in
    ///            router.crud(at: "foo", children: \.$planets) { planetRouter in
    ///                planetRouter.crud(parent: \.$galaxy)
    ///            }
    ///        }
    ///        ```
    public func crud<ChildType>(
        at path: [PathComponent],
        children relation: KeyPath<TargetType, ChildrenProperty<TargetType, ChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod> = .only(ChildrenRouterMethod.allCases),
        relationConfiguration: ((CrudChildrenController<TargetType, ChildType>) -> Void)?=nil
    ) where
        ChildType: Model & Content
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: ChildType.self)

        let fullPath = baseIdPath + adjustedPath

        let controller: CrudChildrenController<TargetType, ChildType>

        switch either {
        case .only(let methods):
            controller = CrudChildrenController(
                childrenRelation: relation,
                path: fullPath,
                router: self.router,
                activeMethods: Set(methods)
            )
        case .except(let methods):
            let allMethods = Set(ChildrenRouterMethod.allCases)
            controller = CrudChildrenController(
                childrenRelation: relation,
                path: fullPath,
                router: self.router,
                activeMethods: allMethods.subtracting(Set(methods))
            )
        }

        do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }

    /// Creates CRUD endpoints for the suplied `relation`.
    ///
    /// By default, the routes will be created that
    ///
    /// - Get an individual child with the provided ID
    /// - Get all children
    /// - Create a new child
    /// - Update a child with the provided ID
    /// - Delete a child with the provided ID
    ///
    /// For example
    ///    ```swift
    ///    router.crud(register: Todo.self) { todoRouter in
    ///        todoRouter.crud("subtasks", children: \.$subtasks)
    ///    }
    ///    ```
    /// Will create the following routes.
    ///
    ///    ```
    ///    GET     /todo/:id/subtasks
    ///    GET     /todo/:id/subtasks/:id
    ///    POST    /todo/:id/subtasks
    ///    PUT     /todo/:id/subtasks/:id
    ///    DELETE  /todo/:id/subtasks/:id
    ///    ```
    ///
    /// - Parameter path: Overrides the path instead of using the default path string.
    /// - Parameter relation: Children relation on the router's model type.
    /// - Parameter either: Users can select a subset of endpoints to generate with `.only()` or exclude a subset of endpoints with `.except()`
    /// - Parameter relationConfiguration: Closure that can be used to configure endpoints for children, parents or siblings of `type`.
    ///
    ///     For example
    ///        ```
    ///        app.crud("foo", register: Galaxy.self) { router in
    ///            router.crud(at: "foo", children: \.$planets) { planetRouter in
    ///                planetRouter.crud(parent: \.$galaxy)
    ///            }
    ///        }
    ///        ```
    public func crud<ChildType>(
        at path: PathComponent...,
        children relation: KeyPath<TargetType, ChildrenProperty<TargetType, ChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod> = .only(ChildrenRouterMethod.allCases),
        relationConfiguration: ((CrudChildrenController<TargetType, ChildType>) -> Void)?=nil
    ) where
        ChildType: Model & Content
    {
        crud(at: path, children: relation, either, relationConfiguration: relationConfiguration)
    }

    /// Creates CRUD endpoints for the suplied `relation`.
    ///
    /// By default, the routes will be created that
    ///
    /// - Get an individual sibling with the provided ID
    /// - Get all siblings
    /// - Create a new sibling
    /// - Update a sibling with the provided ID
    /// - Delete a sibling with the provided ID
    ///
    /// For example
    ///    ```swift
    ///    router.crud(register: Todo.self) { todoRouter in
    ///        todoRouter.crud("tags", siblings: \.$tags)
    ///    }
    ///    ```
    /// Will create the following routes.
    ///
    ///    ```
    ///    GET     /todo/:id/tags
    ///    GET     /todo/:id/tags/:id
    ///    POST    /todo/:id/tags
    ///    PUT     /todo/:id/tags/:id
    ///    DELETE  /todo/:id/tags/:id
    ///    ```
    ///
    /// - Parameter path: Overrides the path instead of using the default path string.
    /// - Parameter relation: Sibling relation on the router's model type.
    /// - Parameter either: Users can select a subset of endpoints to generate with `.only()` or exclude a subset of endpoints with `.except()`
    /// - Parameter relationConfiguration: Closure that can be used to configure endpoints for children, parents or siblings of `type`.
    ///
    ///     For example
    ///        ```
    ///        app.crud("foo", register: Planet.self) { router in
    ///            router.crud(at: "foo", siblings: \.$tags) { tagRouter in
    ///                tagRouter.crud(siblings: \.$planets)
    ///            }
    ///        }
    ///        ```
    public func crud<SiblingType, ThroughType>(
        at path: [PathComponent],
        siblings relation: KeyPath<TargetType, SiblingsProperty<TargetType, SiblingType, ThroughType>>,
        _ either: OnlyExceptEither<SiblingRouterMethod> = .only(SiblingRouterMethod.allCases),
        relationConfiguration: ((CrudSiblingsController<TargetType, SiblingType, ThroughType>) -> Void)?=nil
    ) where
        SiblingType: Content,
        ThroughType: Model
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: SiblingType.self)

        let fullPath = baseIdPath + adjustedPath

        let controller: CrudSiblingsController<TargetType, SiblingType, ThroughType>

        switch either {
        case .only(let methods):
            controller = CrudSiblingsController(
                siblingRelation: relation,
                path: fullPath,
                router: self.router,
                activeMethods: Set(methods)
            )
        case .except(let methods):
            let allMethods = Set(SiblingRouterMethod.allCases)
            controller = CrudSiblingsController(
                siblingRelation: relation,
                path: fullPath,
                router: self.router,
                activeMethods: allMethods.subtracting(Set(methods))
            )
        }

        do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }

    /// Creates CRUD endpoints for the suplied `relation`.
    ///
    /// By default, the routes will be created that
    ///
    /// - Get an individual sibling with the provided ID
    /// - Get all siblings
    /// - Create a new sibling
    /// - Update a sibling with the provided ID
    /// - Delete a sibling with the provided ID
    ///
    /// For example
    ///    ```swift
    ///    router.crud(register: Todo.self) { todoRouter in
    ///        todoRouter.crud("tags", siblings: \.$tags)
    ///    }
    ///    ```
    /// Will create the following routes.
    ///
    ///    ```
    ///    GET     /todo/:id/tags
    ///    GET     /todo/:id/tags/:id
    ///    POST    /todo/:id/tags
    ///    PUT     /todo/:id/tags/:id
    ///    DELETE  /todo/:id/tags/:id
    ///    ```
    ///
    /// - Parameter path: Overrides the path instead of using the default path string.
    /// - Parameter relation: Sibling relation on the router's model type.
    /// - Parameter either: Users can select a subset of endpoints to generate with `.only()` or exclude a subset of endpoints with `.except()`
    /// - Parameter relationConfiguration: Closure that can be used to configure endpoints for children, parents or siblings of `type`.
    ///
    ///     For example
    ///        ```
    ///        app.crud("foo", register: Planet.self) { router in
    ///            router.crud(at: "foo", siblings: \.$tags) { tagRouter in
    ///                tagRouter.crud(siblings: \.$planets)
    ///            }
    ///        }
    ///        ```
    public func crud<SiblingType, ThroughType>(
        at path: PathComponent...,
        siblings relation: KeyPath<TargetType, SiblingsProperty<TargetType, SiblingType, ThroughType>>,
        _ either: OnlyExceptEither<SiblingRouterMethod> = .only(SiblingRouterMethod.allCases),
        relationConfiguration: ((CrudSiblingsController<TargetType, SiblingType, ThroughType>) -> Void)?=nil
    ) where
        SiblingType: Content,
        ThroughType: Model
    {
        crud(at: path, siblings: relation, either, relationConfiguration: relationConfiguration)
    }
}
