import gleam/result
import server/error
import sqlight

pub type Connection =
  sqlight.Connection

pub fn with_connection(name: String, f: fn(Connection) -> a) {
  use db <- sqlight.with_connection(name)
  let assert Ok(_) = sqlight.exec("pragma foreign_keys = on;", db)
  f(db)
}

pub fn migrate_schema(db: Connection) -> Result(Nil, error.AppError) {
  sqlight.exec(
    "
    create table if not exists users (
      id integer primary key autoincrement not null
    ) strict;",
    db,
  )
  |> result.map_error(error.SqlightError)
}
