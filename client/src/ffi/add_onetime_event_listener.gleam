import plinth/browser/element.{type Element}

@external(javascript, "../add_onetime_event_listener.mjs", "add_onetime_event_listener")
pub fn add_onetime_event_listener(
  element: Element,
  event_name: String,
  event_function: fn() -> Nil,
) -> Nil
