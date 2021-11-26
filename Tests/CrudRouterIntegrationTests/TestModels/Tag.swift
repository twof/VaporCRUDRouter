import FluentKit
import Vapor

final class Tag: Model, Content {
    static let schema = "tags"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    var planets: [Planet]

    init() { }

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct TagMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tags")
            .field("id", .uuid, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tags").delete()
    }
}
