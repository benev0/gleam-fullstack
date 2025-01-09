import gleam/int
import gleam/option
import gleam/result
import server/database
import wisp

pub type Context {
  Context(
    user_id: option.Option(Int),
    db: database.Connection,
    static_path: String,
  )
}

const uid_cookie = "uid"

pub fn authenticate(
  req: wisp.Request,
  ctx: Context,
  next: fn(Context) -> wisp.Response,
) -> wisp.Response {
  let id =
    wisp.get_cookie(req, uid_cookie, wisp.Signed)
    |> result.try(int.parse)
    |> option.from_result

  let context = Context(..ctx, user_id: id)
  let resp = next(context)
  resp
}

pub type LoginInfo {
  LoginInfo(username: String, password: String)
}

pub fn attempt_login(
  req: wisp.Request,
  resp: wisp.Response,
  cred: LoginInfo,
) -> #(option.Option(Int), wisp.Response) {
  wisp.log_info("login attempt begin")
  let id = int.to_string(1)
  let year = 60 * 60 * 24 * 365
  #(
    option.Some(1),
    wisp.set_cookie(resp, req, uid_cookie, id, wisp.Signed, year),
  )
}
