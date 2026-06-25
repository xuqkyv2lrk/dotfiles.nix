/*
 * river-tag-watcher — emits River tag state as JSON lines to stdout.
 *
 * Subscribes to river-status-unstable-v1 for every output the compositor
 * announces.  On any state change it prints one line per output:
 *
 *   {"output":"eDP-1","focused_tags":1,"urgent_tags":0,"view_tags":[1,2,1]}
 *
 * Output discovery is fully dynamic: hotplugged outputs are picked up via
 * the wl_registry global event and subscribed automatically once the status
 * manager is available.
 */

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>
#include "river-status-unstable-v1-client-protocol.h"

#define MAX_VIEWS 512

/* Per-output tracking node. */
struct output {
    struct wl_output              *wl_output;
    struct zriver_output_status_v1 *river_status;
    char                          *name;
    uint32_t                       registry_name; /* for hotplug removal */
    uint32_t                       focused_tags;
    uint32_t                       urgent_tags;
    uint32_t                       view_tags[MAX_VIEWS];
    size_t                         view_count;
    struct output                 *next;
};

static struct zriver_status_manager_v1 *status_manager = NULL;
static struct output                   *outputs        = NULL;

/* ------------------------------------------------------------------ emit */

static void emit(const struct output *out) {
    if (!out->name) return;

    printf("{\"output\":\"%s\",\"focused_tags\":%u,\"urgent_tags\":%u,"
           "\"view_tags\":[",
           out->name, out->focused_tags, out->urgent_tags);

    for (size_t i = 0; i < out->view_count; i++) {
        if (i > 0) putchar(',');
        printf("%u", out->view_tags[i]);
    }

    printf("]}\n");
    fflush(stdout);
}

/* --------------------------------------------------------- output status */

static void handle_focused_tags(void *data,
        struct zriver_output_status_v1 *status, uint32_t tags) {
    struct output *out = data;
    out->focused_tags = tags;
    emit(out);
}

static void handle_view_tags(void *data,
        struct zriver_output_status_v1 *status, struct wl_array *tags) {
    struct output *out = data;
    size_t i = 0;
    uint32_t *tag;
    wl_array_for_each(tag, tags) {
        if (i < MAX_VIEWS) out->view_tags[i++] = *tag;
    }
    out->view_count = i;
    emit(out);
}

static void handle_urgent_tags(void *data,
        struct zriver_output_status_v1 *status, uint32_t tags) {
    struct output *out = data;
    out->urgent_tags = tags;
    emit(out);
}

static void handle_layout_name(void *data,
        struct zriver_output_status_v1 *status, const char *name) {}

static void handle_layout_name_clear(void *data,
        struct zriver_output_status_v1 *status) {}

static const struct zriver_output_status_v1_listener output_status_listener = {
    .focused_tags      = handle_focused_tags,
    .view_tags         = handle_view_tags,
    .urgent_tags       = handle_urgent_tags,
    .layout_name       = handle_layout_name,
    .layout_name_clear = handle_layout_name_clear,
};

/* ---------------------------------------------------------------- outputs */

static void subscribe_output(struct output *out) {
    if (out->river_status || !status_manager || !out->wl_output) return;
    out->river_status = zriver_status_manager_v1_get_river_output_status(
        status_manager, out->wl_output);
    zriver_output_status_v1_add_listener(out->river_status,
        &output_status_listener, out);
}

static void wl_output_geometry(void *data, struct wl_output *wl_output,
    int32_t x, int32_t y, int32_t pw, int32_t ph,
    int32_t subpixel, const char *make, const char *model,
    int32_t transform) {}

static void wl_output_mode(void *data, struct wl_output *wl_output,
    uint32_t flags, int32_t w, int32_t h, int32_t refresh) {}

static void wl_output_done(void *data, struct wl_output *wl_output) {
    /* Called after all output properties (including name) are sent.
     * Safe to subscribe here for outputs that appear after startup. */
    subscribe_output((struct output *)data);
}

static void wl_output_scale(void *data, struct wl_output *wl_output,
    int32_t factor) {}

static void wl_output_name(void *data, struct wl_output *wl_output,
    const char *name) {
    struct output *out = data;
    free(out->name);
    out->name = strdup(name);
}

static void wl_output_description(void *data, struct wl_output *wl_output,
    const char *description) {}

static const struct wl_output_listener wl_output_listener = {
    .geometry    = wl_output_geometry,
    .mode        = wl_output_mode,
    .done        = wl_output_done,
    .scale       = wl_output_scale,
    .name        = wl_output_name,
    .description = wl_output_description,
};

/* --------------------------------------------------------------- registry */

static void registry_global(void *data, struct wl_registry *registry,
        uint32_t name, const char *interface, uint32_t version) {

    if (strcmp(interface, zriver_status_manager_v1_interface.name) == 0) {
        status_manager = wl_registry_bind(registry, name,
            &zriver_status_manager_v1_interface,
            version < 4 ? version : 4);

        /* Subscribe any outputs that appeared before the status manager. */
        for (struct output *out = outputs; out; out = out->next)
            subscribe_output(out);

    } else if (strcmp(interface, wl_output_interface.name) == 0) {
        struct output *out = calloc(1, sizeof(*out));
        if (!out) return;

        out->registry_name = name;
        out->wl_output = wl_registry_bind(registry, name,
            &wl_output_interface, version < 4 ? version : 4);
        wl_output_add_listener(out->wl_output, &wl_output_listener, out);

        out->next = outputs;
        outputs   = out;

        /* If status_manager is already available, subscribe will be called
         * from wl_output_done once the name event arrives. */
    }
}

static void registry_global_remove(void *data, struct wl_registry *registry,
        uint32_t name) {
    /* Remove the output from our list on hotplug removal. */
    struct output **prev = &outputs;
    for (struct output *out = outputs; out; out = out->next) {
        if (out->registry_name == name) {
            *prev = out->next;
            if (out->river_status)
                zriver_output_status_v1_destroy(out->river_status);
            if (out->wl_output)
                wl_output_destroy(out->wl_output);
            free(out->name);
            free(out);
            return;
        }
        prev = &out->next;
    }
}

static const struct wl_registry_listener registry_listener = {
    .global        = registry_global,
    .global_remove = registry_global_remove,
};

/* ------------------------------------------------------------------  main */

int main(void) {
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "river-tag-watcher: failed to connect to Wayland display\n");
        return 1;
    }

    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);

    /* First roundtrip: bind globals (status_manager + all current outputs). */
    wl_display_roundtrip(display);
    /* Second roundtrip: receive wl_output.name / wl_output.done events,
     * triggering subscribe_output for any output not yet subscribed. */
    wl_display_roundtrip(display);

    if (!status_manager) {
        fprintf(stderr, "river-tag-watcher: compositor does not advertise "
                "river-status-unstable-v1\n");
        wl_display_disconnect(display);
        return 1;
    }

    /* Third roundtrip: receive initial focused_tags / view_tags / urgent_tags
     * events for all subscribed outputs. */
    wl_display_roundtrip(display);

    /* Main event loop — runs until the compositor disconnects or we get
     * a signal.  New outputs (hotplug) are handled in registry_global and
     * wl_output_done above. */
    while (wl_display_dispatch(display) >= 0) {}

    wl_display_disconnect(display);
    return 0;
}
