import FluentSQLiteDriver
import Vapor

public final class Planet: Model, Content {
    public static let schema = "planets"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Parent(key: "galaxy_id")
    public var galaxy: Galaxy

    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]

    public init() { }

    public init(id: UUID? = nil, name: String, galaxyID: Galaxy.IDValue) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}

public struct PlanetMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("planets")
            .field("id", .uuid, .identifier(auto: true))
            .field("name", .string, .required)
            .field("galaxy_id", .int, .required)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("planets").delete()
    }
}
