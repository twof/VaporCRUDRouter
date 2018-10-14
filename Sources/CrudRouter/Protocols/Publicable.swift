import Fluent
import Vapor

public protocol Publicable {
    associatedtype PublicModel: Model & Content
    
    func `public`(on conn: DatabaseConnectable) -> PublicModel
}
