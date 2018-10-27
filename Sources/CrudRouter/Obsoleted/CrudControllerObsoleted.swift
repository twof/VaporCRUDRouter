import Vapor
import Fluent

// MARK: Obsolted ParentsController methods
extension CrudController {
    @available(swift, obsoleted: 4.0, renamed: "crud(at:parent:relationConfiguration:)")
    public func crudRegister<ParentType>(
        at path: PathComponentsRepresentable...,
        forParent relation: KeyPath<ModelType, Parent<ModelType, ParentType>>,
        relationConfiguration: ((CrudParentController<ModelType, ParentType>) throws -> Void)?=nil
    ) throws where
        ParentType: Model & Content,
        ModelType.Database == ParentType.Database,
        ParentType.ID: Parameter {
            fatalError()
    }
}


// MARK: ChildController methods
extension CrudController {
    @available(swift, obsoleted: 4.0, renamed: "crud(at:children:relationConfiguration:)")
    public func crudRegister<ChildType>(
        at path: PathComponentsRepresentable...,
        forChildren relation: KeyPath<ModelType, Children<ModelType, ChildType>>,
        relationConfiguration: ((CrudChildrenController<ChildType, ModelType>) throws -> Void)?=nil
    ) throws where
        ChildType: Model & Content,
        ModelType.Database == ChildType.Database,
        ChildType.ID: Parameter {
            fatalError()
    }
}

// MARK: SiblingController methods
public extension CrudController {
    @available(swift, obsoleted: 4.0, renamed: "crud(at:siblings:relationConfiguration:)")
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
            fatalError()
    }

    @available(swift, obsoleted: 4.0, renamed: "crud(at:siblings:relationConfiguration:)")
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
            fatalError()
    }
}
