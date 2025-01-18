import gleam/erlang/process
import gleam/option
import mist
import server/database
import server/router
import server/web
import wisp
import wisp/wisp_mist

const db_name = "db.db"

pub fn main() {
  wisp.configure_logger()

  let port = load_port()

  let secret_key_base = load_application_secret()

  let assert Ok(priv) = wisp.priv_directory("server")
  let static_dir = priv <> "/static"

  let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)

  let handle_request = fn(req) {
    use db <- database.with_connection(db_name)
    let ctx = web.Context(user_id: option.None, db: db, static_path: static_dir)
    router.handle_request(req, ctx)
  }

  let assert Ok(_) =
    handle_request
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}

fn load_application_secret() -> String {
  "100"
  //wisp.random_string(64)
}

fn load_port() -> Int {
  4200
}
