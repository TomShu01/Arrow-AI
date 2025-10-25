
*Frame* nodes are designed to serve as Arrow editor's grid helpers.

They are resizable rectangles that group other grid nodes covered under their surface area.

Frames have a `label` to provide information on their purpose or contents,
as well as a `rect` (i.e. [width, height]), and a `color`
defining their visual appearance and function.

### Conventions:

+ Frame nodes accept no incoming or outgoing connections, but may be [Jump] destinations.
In that case, they behave similar to End-of-Line [Marker] nodes.
This is not recommended or expected behavior for Frames, but a fallback,
so runtime implementations may throw a warning if a Jump into a Frame is observed.

### Use:

Frames are added to the grid like other nodes.

They can be resized from their bottom-right corner.

Frame nodes try to move and stay behind their wrapped nodes on mouse leave.
They can also be temporarily collapsed using a button on their top-right corner.

Frame nodes move independently.
To move all their contents as well, use `Ctrl + Alt + Double-Click`
on their top bar or surface where no other node is covered.

`Alt + Double-Click` on a covered node will select that very node.
Together with `Ctrl` you can select multiple covered nodes.

### See also:

+ [Marker]
    > For annotations and visual cues.



<!-- relative -->
[Jump]: ./jump
[Marker]: ./marker
