
Arrow chapter documents structure looks like this, in the topmost level:

```JS
{
    "title": "Untitled Adventure",
    "entry": 1, // Resource-UID of the document/chapter's main (active) entry node
    "meta": {
        // Native (default) distributed UID metadata:
        // > For larger projects which are divided into multiple `.arrow` files,
        // > setting different chapter IDs per document (sub-project) guarantees global uniqueness of each resource UID.
        // > This allows running different chapters in the same runtime environment without any collision.
        // > Up to 1024 chapters, represented as the 1st 9 bits in each UID, can exist.
        "chapter": 0, // (0 - 1024; Order is optional.)
        // > Arrow uses an incremental seed tracker for each author to guarantee resource UID uniqueness
        // > when multiple users work on the same document at the same time.
        "authors": {
            // > Up to 64 authors, represented as the next 6 bits in each UID, can contribute simultaneously.
            0: [Settings.ANONYMOUS_AUTHOR_INFO, 3] // [Author info, and incremental seed for the next UID]
        },
        // ...
        // Time-based distributed UID epoch:
        // > Alternatively to the default (chapter×author×seed) model of distributed UID creation,
        // > You can set an epoch property, to get 64-bit time-based distributed UIDs inspired by Snowflake-IDs.
        // > This property should be unix time (UTC in microseconds) of creation of the *project* (not the document).
        // > This method (time×author×sequence-id) is not recommended. For most projects, the default method is a much better choice.
        // "epoch": null,
        // ...
        "last_save": null, // UTC date-time (ISO 8601) string of the latest save moment
        "editor": Settings.ARROW_VERSION, // (for version compatibility checks)
        // ...
        // Arrow has a vcs-friendly project structure (i.e. unique & never-reused resource-ids, JSON exports, etc.)
        // so you can easily use your favorite revision system, such as Git. The properties `offline` and `remote`
        // are mainly reserved for possible editor vcs integration in the future, although there is no official plan for it.
        // NOTE: Do not remove these metadata, as they may have been used for other purposes or by infrastructural functionalities.
        "offline": true,
        "remote": {},
    },
    // ...
    // Global incremental UID tracker (DEPRECATED):
    // > If exists, we move this global seed to the author `0` on chapter `0` for backward compatibility.
    // "next_resource_seed": <int>,
    // ...
    // And finally where all the resources (such as scenes, nodes, variables, etc.) are:
	"resources": {
        // ...
    }
}
```

> JSON exports share the same structure, but do not include metadata such as developer notes.
> Other formats such as playable `.html` also come with similar data embedded.
> These files are suitable for testing, review or play; but if you need to re-import data to edit,
> your best option would be going with `.arrow` save files which is formatted in JSON and keeps all the data.

Deeper down, building blocks of every Arrow project are `resources`.

Each resource is known to Arrow with a Unique Identifier (UID).
These UIDs are distributed by design and would not exceed 64 bits.

> Actually, our `Native` algorithm is configured by default to generates 53-bit UIDs to fit into double-precision floats,
> which makes it suitable for more restricted languages where big-int (64-bit) is not available.

UIDs are set by Arrow and shall not be edited manually in the saved data (unless you really know what you're doing).
The (legacy) `[U]ID` fields in the inspectors, where you can edit a resource's identity, actually edits the `name`
parameter of each resource that reflects the underlying immutable UID (initially as a base-36 representation),
and helps identifying nodes more human-friendly.

Arrow *does not* recycle UIDs, and *never (re-)uses* a UID or name for different resources by default.

> For more information on UID and Name parameters, check out [Project Organization][project-organization] page.

There are four main resource types:
+ Scenes & Macros
+ Nodes
+ Variables
+ Characters

All the resources are sorted by UIDs, grouped under their respective types, in the `resources` tree.
Following pseudo-code shows their overall structure:

```JS
{
    // ...,
    "resources": {
        "scenes" : { // (& macros)
            uid<i64>: { // <Resource UID of the scene>
                "name": String<display-name>,
                "entry": int<entry-node-uid>,
                "map": { // How and in which order, nodes are connected in the parent scene:
                    uid<int>: { // <Resource UID of the (child) node in the scene>
                        "offset": [int<x>, int<y>], // The node's Position on the grid
                        "skip": bool^optional,
                        "io": [ // List of the node's *outgoing* connections, not sorted
                            [ int<from_uid>, int<from_slot>, int<to_uid>, int<to_slot> ],
                            ...
                        ],
                    }, 
                    ...
                },
                "macro": bool^optional // Marks this scene as a reusable asset, a macro.
            },
            ...
        },
        "nodes" : {
            uid<int>: {
                "type": String/Enum<node-type>,
                "name": String<display-name>,
                "data": {
                    // [depended on the node type]
                },
                "notes": String^optional
            },
            ...
        },
        "characters": {
            uid<int>: {
                "name": String<display-name>,
                "color": String<display-color>, // RGB[A] (hex, HTML color)
                "tags": {
                    // User-defined custom data
                    String<key>: String<value>, ...
                }
            },
            ... 
        },
        "variables": {
            uid<int>: {
                "type": String/Enum<num|str|bool>,
                "name": String<display-name>,
                "init": Variant<initial-value>
            },
            ...
        }
    }
}
```

Variable and node resources have a `type` property that defines
what sort of `init`ial value or `data` we expect to have there, and how should such data be handled.

For brevity, only one side of each graph connection (two nodes on the grid), needs to, and does keep the `io` data.
Conventionally, they are outgoing connections, offering advantage of faster next node lookup.

There can be an optional `use` property (array) for each resource as well, indicating which other (user) resources rely on this one.
Another property `ref` complements `use` by listing all the used (referred) resources for any dependent resource.

> `use` and `ref` properties are considered metadata, and exist chiefly to safeguard continuities during operations such as node removal,
> or to ease locating nodes using another resource. All the play-oriented relations (e.g. target node of a Jump)
> should be kept among the `data` properties of the node as other metadata may not be available at runtime.

One scene, and one [Entry] node are required in every valid document, so the console or runtime environment knows where to start.

> Any node can be set as an entry (by manually editing the document);
> but the specified type provides multiple safety checks and is the only way supported by the editor.

Chapter files, are *JSON-compatible*, so complex data types are converted on save, load, import and export.
For example, a `Vector2(x,y)` would be stored as ann `Array[x,y]` and Integer keys (or UIDs) are saved as Strings.

Macros are *re-usable `scenes`*, with their property `macro = true`, making them to act differently both in the editor and runtime.

> Make sure to check out [Project Organization][project-organization] for more detailed technical information
> about underlying procedures and how you can use them to stay in control of your projects growing in size.



<!-- References -->
[project-organization]: ./project-organization
[Entry]: ./entry
