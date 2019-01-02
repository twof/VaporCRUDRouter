import Fluent
import Vapor

public protocol Publicable {
    associatedtype PublicModel: Content
    
    func `public`(on conn: DatabaseConnectable) throws -> Future<PublicModel>
}
