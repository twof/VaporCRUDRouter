import FluentKit
import Foundation

struct SiblingSeeding: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return SiblingSeeding.tags.map { tag in
            return tag
            .save(on: database)
            .transform(to: ())
            .flatMap { tag.$planets.attach(ChildSeeding.planets[0], on: database).transform(to: ()) }
        }.flatten(on: database.eventLoop)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return SiblingSeeding.tags.map { tag in
            [
                tag.$planets.detach(ChildSeeding.planets[0], on: database),
                tag.delete(on: database).transform(to: ())
            ].flatten(on: database.eventLoop)
        }.flatten(on: database.eventLoop)
    }

    static let lifeSupportingId = UUID()
    static var tags: [Tag] {
        [Tag(id: lifeSupportingId, name: "Life-Supporting")]
    }
}

