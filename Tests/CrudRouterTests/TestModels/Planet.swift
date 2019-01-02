import FluentSQLite
import Vapor
import CrudRouter

public struct Planet: SQLiteModel {
    public var id: Int?
    public var name: String
    public var galaxyID: Int

    public init(id: Int?=nil, name: String, galaxyID: Int) {
        self.id = id
        self.name = name
        self.galaxyID = galaxyID
    }
}

extension Planet {
    // this planet's related galaxy
    var galaxy: Parent<Planet, Galaxy> {
        return parent(\.galaxyID)
    }
}

extension Planet {
    // this planet's related tags
    var tags: Siblings<Planet, Tag, PlanetTag> {
        return siblings()
    }
}

extension Planet: Content { }
extension Planet: Migration { }
extension Planet: Publicable {
    public struct PublicPlanet: Content {
        var nameAndId: String
    }
    
    public func `public`(on conn: DatabaseConnectable) throws -> EventLoopFuture<PublicPlanet> {
        return conn.future(PublicPlanet(nameAndId: "\(String(self.id ?? 0))\(self.name)"))
    }
}
