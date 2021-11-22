import Vapor
import FluentKit
import CrudRouter
import Foundation

public final class Galaxy: Model, Content {
    public static let schema = "galaxies"

    public static var migration: Migration {
        return GalaxyMigration()
    }
    
    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Children(for: \.$galaxy)
    public var planets: [Planet]

    public init() { }

    public init(id: UUID? = nil, name: String) {
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
