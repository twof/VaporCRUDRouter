import Vapor
import Fluent

extension Request {
    func getId<T>() throws -> T where T: LosslessStringConvertible {
        guard let id: T = self.parameters.get("id") else { fatalError() }

        return id
    }
}
