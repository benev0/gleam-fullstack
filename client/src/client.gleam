import decipher
import ffi/add_onetime_event_listener
import ffi/cache_function
import gleam/dict
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

import plinth/browser/document
import plinth/browser/element as dom_element

const app_selector: String = "#client"

const container_selector: String = "#tab-content"

pub fn main() {
  cache_function.cache_function("list_main", start_app)
}

fn start_app() {
  let maybe_element = document.query_selector(container_selector)

  let app = lustre.application(init, update, view)
  let assert Ok(app_runtime) = lustre.start(app, app_selector, Nil)

  case maybe_element {
    Ok(element) -> {
      add_onetime_event_listener.add_onetime_event_listener(
        element,
        "htmx:afterSwap",
        fn() { lustre.shutdown() |> app_runtime },
      )
    }
    Error(_) -> {
      Nil
    }
  }

  Nil
}

type Model =
  dict.Dict(String, Int)

fn init(_) -> #(Model, Effect(Msg)) {
  let model = dict.new()
  let effect = effect.none()

  #(model, effect)
}

type Msg {
  ServerSavedList(Result(Nil, String))
  UserAddedProduct(name: String)
  UserSavedList
  UserUpdatedQuantity(name: String, amount: Int)
  ExternalSignal(signal: effect.Effect(Msg))
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ServerSavedList(_) -> {
      #(model, effect.none())
    }
    UserAddedProduct(item) -> #(
      dict.upsert(model, item, fn(new) {
        case new {
          option.Some(a) -> a + 1
          _ -> 1
        }
      }),
      effect.none(),
    )
    UserSavedList -> {
      #(model, effect.none())
    }
    UserUpdatedQuantity(item, quantity) -> #(
      case quantity {
        0 -> dict.delete(model, item)
        v -> dict.insert(model, item, v)
      },
      effect.none(),
    )
    ExternalSignal(signal) -> {
      // lustre.shutdown()
      #(dict.new(), effect.batch([signal]))
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  let styles = [
    #("max-width", "30ch"),
    #("margin", "0 auto"),
    #("display", "flex"),
    #("flex-direction", "column"),
    #("gap", "1em"),
  ]

  let handle_click = fn(_event) { Ok(ExternalSignal(effect.none())) }

  html.div([attribute.style(styles)], [
    view_grocery_list(model),
    view_new_item(),
    html.div([], [
      html.button([event.on("click", handle_click)], [html.text("Sync")]),
    ]),
  ])
}

fn view_new_item() -> Element(Msg) {
  let handle_click = fn(event) {
    let path = ["target", "previousElementSibling", "value"]

    event
    |> decipher.at(path, dynamic.string)
    |> result.map(UserAddedProduct)
  }

  html.div([], [
    html.input([]),
    html.button([event.on("click", handle_click)], [html.text("Add")]),
  ])
}

fn view_grocery_list(model: Model) -> Element(Msg) {
  let styles = [#("display", "flex"), #("flex-direction", "column-reverse")]

  element.keyed(html.div([attribute.style(styles)], _), {
    use #(name, quantity) <- list.map(dict.to_list(model))
    let item = view_grocery_item(name, quantity)

    #(name, item)
  })
}

fn view_grocery_item(name: String, quantity: Int) -> Element(Msg) {
  let handle_input = fn(e) {
    event.value(e)
    |> result.replace_error(Nil)
    |> result.then(int.parse)
    |> result.map(UserUpdatedQuantity(name, _))
    |> result.replace_error([])
  }

  html.div([attribute.style([#("display", "flex"), #("gap", "1em")])], [
    html.span([attribute.style([#("flex", "1")])], [html.text(name)]),
    html.input([
      attribute.style([#("width", "4em")]),
      attribute.type_("number"),
      attribute.value(int.to_string(quantity)),
      attribute.min("0"),
      event.on("input", handle_input),
    ]),
  ])
}
