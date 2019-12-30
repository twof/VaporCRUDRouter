import Vapor
import Fluent

extension Request {
    func getId<M: Model>(modelType: M.Type) throws -> M.IDValue where M.IDValue: LosslessStringConvertible {
        guard let id: M.IDValue = self.parameters.get("\(modelType.schema)ID") else { fatalError() }

        return id
    }
}
