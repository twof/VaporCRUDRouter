import Vapor
import Fluent

extension Request {
    func getId<T: ID & Parameter>() throws -> T {
        guard let id = try self.parameters.next(T.self) as? T else { fatalError() }

        return id
    }
}
