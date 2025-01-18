export function add_onetime_event_listener(element, event_name, event_function) {
    let onetime_fn = () => {
        element.removeEventListener(event_name, onetime_fn);
        event_function();
    }
    return element.addEventListener(event_name, onetime_fn);
}
