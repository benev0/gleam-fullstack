export function cache_function(name, main_fn) {
    if (!document.lustre) {
        document.lustre = {};
    }
    document.lustre[name] = main_fn;
}
