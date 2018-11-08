import Vapor
import FluentSQLite
import CrudRouter

struct Galaxy: SQLiteModel {
    var id: Int?
    var name: String

    public init(id: Int?=nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension Galaxy {
    // this galaxy's related planets
    var planets: Children<Galaxy, Planet> {
        return children(\.galaxyID)
    }
}

extension Galaxy: Content { }
extension Galaxy: Migration { }
extension Galaxy: Parameter { }
extension Galaxy: Returnable {  }

extension Galaxy: Publicable {
    public struct PublicGalaxy: Content {
        var nameAndId: String
    }
    
    func `public`(on conn: DatabaseConnectable) throws -> EventLoopFuture<PublicGalaxy> {
        return conn.future(PublicGalaxy(nameAndId: "\(String(self.id ?? 0))\(self.name)"))
    }
}
