
if (!customElements.get('client-app')) {
    customElements.define('client-app', class ClientApp extends HTMLElement {
        connectedCallback() {
            const shadow = this.attachShadow({ mode: 'closed' });

            const script_elem = document.createElement("script");
            script_elem.src = "/client.mjs";

            shadow.appendChild(script_elem);
        }
    });
}
