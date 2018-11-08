import FluentSQLite
import Vapor
import CrudRouter

struct Tag: SQLiteModel {
    var id: Int?
    var name: String
}

extension Tag {
    // all planets that have this tag
    var planets: Siblings<Tag, Planet, PlanetTag> {
        return siblings()
    }
}

extension Tag: Content { }
extension Tag: Migration { }
extension Tag: Returnable { }
