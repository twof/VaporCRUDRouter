import Vapor
import Fluent

// MARK: Obsolted ParentsController methods
extension CrudController {
    @available(swift, obsoleted: 4.0, renamed: "crud")
    public func crudRegister<ParentType>(
        at path: PathComponentsRepresentable...,
        forParent relation: KeyPath<ModelType, Parent<ModelType, ParentType>>,
        relationConfiguration: ((CrudParentController<ModelType, ParentType>) throws -> Void)?=nil
        ) throws where
        ParentType: Model & Content,
        ModelType.Database == ParentType.Database,
        ParentType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudParentController(relation: relation, basePath: baseIdPath, path: path)

            try controller.boot(router: self.router)
    }
}


// MARK: ChildController methods
extension CrudController {
    @available(swift, obsoleted: 4.0, renamed: "crud")
    public func crudRegister<ChildType>(
        at path: PathComponentsRepresentable...,
        forChildren relation: KeyPath<ModelType, Children<ModelType, ChildType>>,
        relationConfiguration: ((CrudChildrenController<ChildType, ModelType>) throws -> Void)?=nil
        ) throws where
        ChildType: Model & Content,
        ModelType.Database == ChildType.Database,
        ChildType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudChildrenController(childrenRelation: relation, basePath: baseIdPath, path: path)

            try controller.boot(router: self.router)
    }
}

// MARK: SiblingController methods
public extension CrudController {
    @available(swift, obsoleted: 4.0, renamed: "crud")
    public func crudRegister<ChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        forSiblings relation: KeyPath<ModelType, Siblings<ModelType, ChildType, ThroughType>>,
        relationConfiguration: ((CrudSiblingsController<ChildType, ModelType, ThroughType>) throws -> Void)?=nil
        ) throws where
        ChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildType.Database,
        ThroughType.Left == ModelType,
        ThroughType.Right == ChildType {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudSiblingsController(siblingRelation: relation, basePath: baseIdPath, path: path)

            try controller.boot(router: self.router)
    }

    @available(swift, obsoleted: 4.0, renamed: "crud")
    public func crudRegister<ChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        forSiblings relation: KeyPath<ModelType, Siblings<ModelType, ChildType, ThroughType>>,
        relationConfiguration: ((CrudSiblingsController<ChildType, ModelType, ThroughType>) throws -> Void)?=nil
        ) throws where
        ChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildType.Database,
        ThroughType.Right == ModelType,
        ThroughType.Left == ChildType {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudSiblingsController(siblingRelation: relation, basePath: baseIdPath, path: path)

            try controller.boot(router: self.router)
    }
}
