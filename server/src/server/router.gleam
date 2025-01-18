import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/option
import gleam/result
import server/template/index as index_template
import server/template/later as _todo_template
import server/template/list as list_template
import server/template/login as login_template
import server/template/profile as profile_template
import server/template/recipes as recipes_template
import server/web
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use ctx <- web.authenticate(req, ctx)
  use <- wisp.serve_static(req, under: "/", from: ctx.static_path)

  case wisp.path_segments(req) {
    [] -> index(ctx)
    ["login"] -> login(req, ctx)
    ["todo"] -> wisp.not_found()
    ["recipes"] -> recipes(req, ctx)
    ["list"] -> list(req, ctx)
    ["pantry"] -> wisp.not_found()
    ["profile"] -> profile(req, ctx)
    ["profile", _user_id] -> wisp.not_found()
    ["settings"] -> wisp.not_found()
    _ -> wisp.not_found()
  }
}

fn default_route(default_render: String, ctx: web.Context) -> wisp.Response {
  index_template.render_tree(default_render, option.is_some(ctx.user_id))
  |> wisp.html_response(200)
}

fn index(ctx: web.Context) -> wisp.Response {
  let #(sub_content, logged_in) = case ctx.user_id {
    option.Some(n) -> #(profile_template.render(int.to_base36(n)), True)
    option.None -> #(login_template.render(), False)
  }

  index_template.render_tree(sub_content, logged_in)
  |> wisp.html_response(200)
}

fn login_decoder() -> decode.Decoder(web.LoginInfo) {
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(web.LoginInfo(username:, password:))
}

fn login(req: wisp.Request, _ctx: web.Context) -> wisp.Response {
  case req.method {
    http.Put -> {
      wisp.log_info("login attempt 1")
      use json <- wisp.require_json(req)
      wisp.log_info("login attempt 2")
      let result = {
        use login <- result.try(decode.run(json, login_decoder()))
        Ok(login)
      }

      case result {
        Ok(info) -> {
          wisp.log_info("login attempt")
          let resp = wisp.ok()
          let #(user_id, resp_2) = web.attempt_login(req, resp, info)
          case user_id {
            option.Some(id) -> {
              wisp.html_body(
                resp_2,
                index_template.render_tree(
                  profile_template.render(int.to_base36(id)),
                  True,
                ),
              )
            }
            option.None -> {
              wisp.html_body(
                resp_2,
                index_template.render_tree(login_template.render(), False),
              )
            }
          }
        }
        _ -> {
          // if logged in: you are already logged in would you like to log out?
          wisp.log_info("login again")
          login_template.render_tree()
          |> wisp.html_response(200)
        }
      }
    }
    http.Get -> {
      wisp.log_info("getting login page")
      login_template.render_tree()
      |> wisp.html_response(200)
    }
    _ -> wisp.not_found()
  }
}

fn recipes(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  // use require login
  let result = request.get_header(req, "HX-Request")
  case result {
    Ok("true") -> {
      recipes_template.render_tree()
      |> wisp.html_response(200)
    }
    _ -> {
      recipes_template.render()
      |> default_route(ctx)
    }
  }
}

fn profile(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  let result = request.get_header(req, "HX-Request")
  case result {
    Ok("true") -> {
      profile_template.render_tree(int.to_string(option.unwrap(ctx.user_id, 0)))
      |> wisp.html_response(200)
    }
    _ -> {
      profile_template.render(int.to_string(option.unwrap(ctx.user_id, 0)))
      |> default_route(ctx)
    }
  }
}

fn list(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  let result = request.get_header(req, "HX-Request")
  case result {
    Ok("true") -> {
      list_template.render_tree()
      |> wisp.html_response(200)
    }
    _ -> {
      list_template.render()
      |> default_route(ctx)
    }
  }
}
// fn pantry(req: wisp.Request, ctx: web.Context) -> wisp.Response {
//     let result = request.get_header(req, "HX-Request")
//   case result {
//     Ok("true") -> {}
//     _ -> {}
//   }
//   todo
// }
