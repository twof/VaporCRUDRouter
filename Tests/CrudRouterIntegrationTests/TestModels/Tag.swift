import FluentSQLiteDriver
import Vapor

public final class Tag: Model, Content {
    public static let schema = "tags"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]

    public init() { }

    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public struct TagMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tags")
            .field("id", .uuid, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tags").delete()
    }
}
