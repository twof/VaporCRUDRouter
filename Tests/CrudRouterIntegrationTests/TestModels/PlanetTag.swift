import FluentSQLiteDriver
import Foundation

final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    init() { }

    init(planetID: UUID, tagID: UUID) {
        self.$planet.id = planetID
        self.$tag.id = tagID
    }
}

struct PlanetTagMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("planet+tag")
            .field("id", .uuid, .identifier(auto: true))
            .field("planet_id", .uuid, .required)
            .field("tag_id", .uuid, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("planet+tag").delete()
    }
}
