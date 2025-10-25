
Arrow executable accepts following command-line arguments:

+ **`--manual`**

  Shows a brief manual similar to this document.

+ **`--config-dir`**

  Arrow keeps user preferences in a file named `.arrow.config`.
  It is auto-generated and looked for in `res://` or `user://` directory,
  depending on a few factors such as file access permission.

  This argument can change where Arrow prioritizes to save or load a configuration file, for example:

  ```shell
  $ Arrow --config-dir '/home/USER/.config/'
  ```
  
  > Absolute paths and Godot relative paths (starting with `res://` or `user://`) are valid and supported.

  Arrow will create a default config file if it does not exist, but will not create the directory.
  Arrow uses default (hardcoded) configurations, if no config file is found or could be created.

  > **Caution!**  
  > Arrow config file's format and name has changed in different major releases.
  > Trying to re-cycle a configuration file created by older generations
  > (e.g. renaming a v2.x `config.arrow` to a v3.x `.arrow.config`)
  > *will cause unexpected behavior*.

+ **`--sandbox`**

  The editor runs with default configurations in sandbox mode,
  and no `.arrow.config` file will be generated automatically.

+ **`--work-dir`**

  Arrow's convention is to consider each work directory a project divided to multiple `.arrow` chapter documents.
  In other words Arrow editor only uses one particular directory at a time to save and reload `.arrow` files.
  By default the directory is `user://`; but it can be changed from preferences panel or using this argument.

  ```shell
  $ Arrow --work-dir '/home/USER/my_arrow_adventures'
  ```

  > Absolute paths and Godot relative paths (starting with `res://` or `user://`) are valid.

  > Arrow will not create the directory if it doesn't exist.
