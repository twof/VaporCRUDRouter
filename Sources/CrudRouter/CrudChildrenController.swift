import Vapor
import Fluent

public protocol CrudParentControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database

    var relation: KeyPath<ChildType, Parent<ChildType, ParentType>> { get }

    init(relation: KeyPath<ChildType, Parent<ChildType, ParentType>>, basePath: [PathComponentsRepresentable], path: [PathComponentsRepresentable])

    func index(_ req: Request) throws -> Future<ParentType>
    func update(_ req: Request) throws -> Future<ParentType>
}

public extension CrudParentControllerProtocol {

    func index(_ req: Request) throws -> Future<ParentType> {
        let childId: ChildType.ID = try getId(from: req)

        return ChildType.find(childId, on: req).unwrap(or: Abort(.notFound)).flatMap { child in
            child[keyPath: self.relation].get(on: req)
        }
    }

    func update(_ req: Request) throws -> Future<ParentType> {
        let childId: ChildType.ID = try getId(from: req)

        return ChildType.find(childId, on: req).unwrap(or: Abort(.notFound)).flatMap { child in
            return child[keyPath: self.relation].get(on: req)
            }.flatMap { oldParent in
                return try req.content.decode(ParentType.self).flatMap { newParent in
                    var temp = newParent
                    temp.fluentID = oldParent.fluentID
                    return temp.update(on: req)
                }
        }
    }
}

fileprivate extension CrudParentControllerProtocol {
    func getId<T: ID & Parameter>(from req: Request) throws -> T {
        guard let id = try req.parameters.next(T.self) as? T else { fatalError() }

        return id
    }
}

public struct CrudParentController<ChildT: Model & Content, ParentT: Model & Content>: CrudParentControllerProtocol where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public let relation: KeyPath<ChildType, Parent<ChildType, ParentType>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]

    public init(relation: KeyPath<ChildType, Parent<ChildType, ParentType>>, basePath: [PathComponentsRepresentable], path: [PathComponentsRepresentable]) {
        self.relation = relation
        self.basePath = basePath
        self.path = path
    }
}

extension CrudParentController: RouteCollection {
    public func boot(router: Router) throws {

        let parentString
            = self.path.count == 0
                ? [String(describing: ParentType.self).snakeCased()! as PathComponentsRepresentable]
                : self.path

        let parentPath = self.basePath.appending(parentString)
        let parentIdPath = self.basePath.appending(parentString).appending(ParentType.ID.parameter)

        router.get(parentPath, use: self.index)
        router.put(parentIdPath, use: self.update)
    }
}
