import Vapor
import Fluent

public protocol CrudParentControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database

    var relation: KeyPath<ChildType, Parent<ChildType, ParentType>> { get }

    func index(_ req: Request) throws -> Future<ParentType>
    func update(_ req: Request) throws -> Future<ParentType>
}

public extension CrudParentControllerProtocol {

    func index(_ req: Request) throws -> Future<ParentType> {
        let childId: ChildType.ID = try req.getId()

        return ChildType.find(childId, on: req).unwrap(or: Abort(.notFound)).flatMap { child in
            child[keyPath: self.relation].get(on: req)
        }
    }

    func update(_ req: Request) throws -> Future<ParentType> {
        let childId: ChildType.ID = try req.getId()

        return ChildType
            .find(childId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { child in
                return child[keyPath: self.relation].get(on: req)
        }
    }
}

public struct CrudParentController<ChildT: Model & Content, ParentT: Model & Content>: CrudParentControllerProtocol where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public let relation: KeyPath<ChildType, Parent<ChildType, ParentType>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]

    init(relation: KeyPath<ChildType, Parent<ChildType, ParentType>>, basePath: [PathComponentsRepresentable], path: [PathComponentsRepresentable]) {
        let adjustedPath = path.adjustedPath(for: ParentType.self)

        self.relation = relation
        self.basePath = basePath
        self.path = adjustedPath
    }
}

extension CrudParentController: RouteCollection {
    public func boot(router: Router) throws {
        let parentPath = self.basePath.appending(self.path)

        router.get(parentPath, use: self.index)
        router.put(parentPath, use: self.update)
    }
}
