
Hello & Welcome!

In this brief document we cover the basics of Arrow to get started easy and quick.

> For more advance topics and technical information, consider reading other pages of this [wiki][home] as well.


## New Project

Arrow welcomes you with an unsaved almost blank document, every time you open the editor.

To have a new project, you just need to save that untitled document,
by pressing the `Save` button on the title-bar or via
`Inspector (panel) > Project (tab) > New (menu button) > Save Current and Continue`.
> Common [keyboard shortcut][shortcuts] `Ctrl + S` is also available.

You'll be asked for a title and a file name.  
All new files will be created in the [work-directory].

> To import and list a project from file-system use:  
> `Inspector (panel) > Project (tab) > New (menu button) > Import Project File`.


## Where Project Files Are

Arrow keeps all chapters/documents of a project in a single work-directory, as an independent workspace.

This directory is by default `user://` pointing to the platform-specific user local app data directory.

You can change the work-directory's path from [preferences] panel.

> Changing work-directory will not move your project files,
> and if you save an open project, after any change in the work-directory's path,
> it will be regarded as a new project for that new workspace.

Chapter documents are saved in JSON files with `.arrow` extension.

> Compared to `.html` and `.json` (purged) exports targeting production,
> `.arrow` save files include all the editor's meta-data,
> and developers' *node notes*, so are much more suitable to backup,
> track, and re-import projects on development.


## Preferences

Editor configuration is possible from the *Preferences* panel.

> To access it, press the `Arrow` menu button on top-left corner of the editor and select `Preferences`.

This configurations will be kept persistent in `.arrow.config` files.

There are also temporary **Quick Preferences** that control convenient features
such as *Auto Node Update* and *Connection Assist* (both active by default.)
You'll find them on bottom-right corner of the editor.


## Nodes and Graphs

Right Click on the Grid, to insert new nodes.

From the popup menu you can also copy, cut, paste or delete selected nodes.
> Common keyboard [shortcuts] are available for them as well.

> Right clicking on the graph nodes won't select or deselect them.
> It's considered as a normal right click on the grid.

You can change play/execution order of nodes by connecting their slots, the small circles on their sides.

> Visual position of nodes on the grid has no effect on their order of execution.

**Quick node insertion**

Create a connection (incoming or outgoing) to an empty space on the grid,
then from the opened popup, insert the node type you want (double-click or enter).
> This works only if the respective *Quick preference* is active (default).


## Node Inspection

To change how a node behaves, and its parameters,
you can open a node in the *Node* tab of the *Inspector* panel by

+ double-clicking on any node,
+ or just selecting one if *Auto-Inspection* (from [quick preferences][preferences]) is active.

The parameters you can modify depends on type of the node;
yet there are few common properties:

+ Name: The unique text identifier of each node
  > This parameter reflects underlying immutable Integer UID of the node if not changed,
  > but is independent and editable. Normally, the value is kept unique per chapter.
+ Notes: The arbitrary metadata you may add to any node
  > E.g. badges such as WIP, TODO, or Developer Notes.
+ Skip: Deactivates the node (in play-time) without removing it
  > Behavior of each skipped node type depends on its implementation.

Nodes *shall be updated* in order to keep changes,
otherwise when you inspect another node, the changes are gone.

With the quick preference *Auto Node Update* active (default),
inspected nodes get updated automatically when user leaves the node,
in other words when inspects another node or deselects the current one.
> Re-inspecting a node will reset its parameters, to the latest state kept in memory
> and will not trigger auto-update, if the respective quick preference is enabled (default).

Updating nodes, changes them in memory.
To store them permanently, *save* the document.


## Variables and Characters

Some node-types such as [User-Input] or [Dialog],
need a [Variable] or a [Character] to work properly.

To make them, head to the respective tabs in the *Inspector* panel.
> You may need to use arrow buttons on top-right corner of the tab-bar
> to bring other tabs into view, or use the selector button on the panel's titlebar.

> **Note!**  
> Auto-update only works for node. For other resources
> you would need to `set` edited parameters to be applied.

To expose a variable or character tag's value in text nodes
such as [Dialog], [Interaction], [Content], etc.
use mustache placeholders resembling `{variable_name}` or `{CharacterName.tag-key}`.
The Arrow's console and compatible runtime(s) will replace them with their respective current values.


## History of Changes

Early versions of Arrow only supported *Snapshots*, full images of the open document,
serving as manual edit history points that users could create and restore.

A snapshot of a document or a snapshot of another snapshot,
can be taken, previewed or restored into the main working draft,
from the *Project* tab of the *Inspector* panel.

Snapshots can be edited in the preview mode but changes are *volatile*
unless stored by taking another snapshot of the very edited snapshot.
> You can export or save a snapshot as a *copy* via `Inspector > Project > Export`
> while being in preview mode.

A second convenience *Local/Per-Node Modification History* was implemented later,
to track editions for each node individually.

Starting with `v2`, another feature, *History System*, was added
to provide quicker and more convenient undo/redo revision,
by keeping a collection of snapshots in a deck in memory.
> Keyboard [shortcuts] and two buttons on top bar are available for history rotation.

This feature is experimental and still uses full document images akin to snapshots
which could put a burden on devices with visibly low specs when document size is considerably large.
This is why history size preference is zero by default.
Any higher value will automatically activate the history system.

> Quick Tip:  
> Save and [export] functions always save what is currently loaded in the editor,
> whether it is the main working draft, a previewed snapshot, or an undo history point!
> In other words, you can undo a change, or preview a snapshot
> `Save a Copy` and export it, then redo or close the preview and continue
> with no data loss.

Above mentioned features, work independently.


## Test-Play (Console)

You can use the *Console* panel to test-play your creation without exporting it.

There are few buttons on the top-right corner of the editor which open console
and play from a special starting point.

> Console keeps the changes made in the variables and character tags
> while it is not cleared. You can also manually modify them from
> `Console > Settings > Inspect ...`.

Test-playing and manipulating data in the *Console*
will not change your project data, but only the console's memory itself,
so play and test with ease of mind.

> `Double-Click` on non-interactive parts of a node in the console,
> makes the grid to change view and focus on that very node.

## Exporting

When a project is open, you can export it via `Inspector > Project > Export`.

As previously mentioned these functions save what is currently loaded in the editor,
whether it is the main working draft, a previewed snapshot, or an undo history point.

Arrow supports multiple export options including `.json`, `.html` and `.csv`.

+ **`.html`** export will produce a single-file *playable* document
using the [official HTML-JS runtime][runtime-html-js] template.
The generated document can be played in any modern web browser.

+ **`.json`** is also a very popular format you can use in many programming languages and game engines
to further develop your narrative and/or use it as a database of your game content.

  > Compared to full `.arrow` saved file (also in JSON format),
  > exported files may drop metadata and notes (for privacy or brevity reasons).
  > That makes them not really suitable to be re-imported without manual alteration.

+ **`.csv`** exports are added to Arrow mainly to help with internationalization of your projects.

  CSV files can be edited in spreadsheet editors, get extended with translated versions of the originally exported values,
  and then imported in your game's translation system to get proper localized versions of the nodes' text contents.

  The format is **CSV with *tab* (`\t`) column separator and double quotation mark (`"`) as string delimiter**.
  Configure your workflow accordingly while importing the files (e.g. in Godot engine's translation server)
  or when editing them (e.g. opening in LibreOffice Calc).

  The first column always holds "key" pointers to the data and the second one respective "original" values.
  The keys will be in a format resembling `NodeUID-NodeType-Parameter[-Index]`, e.g. `1234-entry-plaque` or `5678-dialog-line-0`.

  > You may want to change the "original" value column's heading to the language of your original text (e.g. "En")
  > to avoid having an extra translation file compiled, if you are importing to a Godot game.

  When exporting from a desktop build of Arrow (not the PWA release), overwriting a file tries to keep your added translation columns
  for all the rows for which the original value is still the same. In other words updating the file instead of overwriting it.
  The removed nodes are always dropped and the result is sorted by keys alphabetically.

  > **Note!**  
  > The feature is relatively rough and new, so use with extra caution and always keep backup(s) of you project.


## Miscellaneous Notes

+ To resize or move floating panels:

  + Grab top-right corner of a panel to resize it
  + Grab a panel's title-bar to move it
  > When panels overlap, grabbing title-bar of any panel will take it
  > to the top layer above others.

+ In addition to the good old Arrow mini-map (displayed on the bottom-left corner),
a larger mini-map (later added to Godot) may be activated using the net-like button
grouped with other grid controls on its top-left corner.



<!-- References -->
<!-- internal -->
[work-directory]: #where-project-files-are
[preferences]: #preferences
[export]: #export
<!-- relative -->
[home]: ./home
[shortcuts]: ./shortcuts
[User-Input]: ./user-input
[Dialog]: ./dialog
[Variable]: ./variables-and-logic
[Character]: ./character
[Interaction]: ./interaction
[Content]: ./content
<!-- absolute -->
[runtime-html-js]: https://github.com/mhgolkar/Arrow/tree/main/runtimes/html-js
