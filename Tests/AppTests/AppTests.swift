import App
import Vapor
import FluentSQLite
import XCTest

final class AppTests: XCTestCase {
    func testNothing() throws {
        var config = Config.default()
        var env = try Environment.detect()
        var services = Services.default()
        try configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        
        let req = Request(using: app)
        
        var future = req.future()
        
        // Insert persons
        var person1 = Person(name: "Person 1")
        var person2 = Person(name: "Person 2")
        future = future.flatMap {
            map(to: Void.self,
                person1.save(on: req).map { person1 = $0 },
                person2.save(on: req).map { person2 = $0 }) { _,_ in
                    return
            }
        }
        
        // Insert message
        future = future.flatMap {
            let message = try Message(from_person_id: person1.requireID(), to_person_id: person2.requireID(), body: "body")
            return message.save(on: req).transform(to: $0)
        }
        
        // Fetch
        future = future.flatMap {_ in 
            req.databaseConnection(to: .sqlite).flatMap { (conn: SQLiteConnection) in
                conn.raw("""
                    SELECT * FROM messages
                    JOIN persons from_persons ON messages.from_person_id = from_persons.id
                    JOIN persons to_persons ON messages.to_person_id = to_persons.id
                    """).all().map { rows in
                        try rows.map { row -> (Message, Person, Person) in
                            // In MySQL, there are row with aliased table name.
                            // In SQLite, however, row has original table name.
                            // And dupulicated columns are omitted.
                            let msg = try conn.decode(Message.self, from: row, table: "messages")
                            let from = try conn.decode(Person.self, from: row, table: "from_persons")
                            let to = try conn.decode(Person.self, from: row, table: "to_persons")
                            return (msg, from, to)
                        }
                }
                }
                .map { print($0) }
        }
        
        try future.wait()
    }

    static let allTests = [
        ("testNothing", testNothing)
    ]
}
