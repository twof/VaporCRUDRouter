import Vapor
import FluentKit

final class Galaxy: Model, Content {
    static let schema = "galaxies"

    static var migration: Migration {
        return GalaxyMigration()
    }
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Children(for: \.$galaxy)
    var planets: [Planet]

    init() { }

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct GalaxyMigration: Migration {
    init() {}
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("galaxies")
            .field("id", .uuid, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("galaxies").delete()
    }
}
