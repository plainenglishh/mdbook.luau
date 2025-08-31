# mdbook.luau

Framework for writing mdBook preprocessors and renderers with Lune.

## Usage

### Writing Preprocessors

The following is an example preprocessor that blanks out every chapter:

```luau
local mdbook = require(...);

-- Create the preprocessor. The 'name' string tells mdbook.luau where to look
-- for options, and what to use as a namespace in `:log()`.
local preprocessor = mdbook.Preprocessor.new("blank");

-- Fetch the `(book.toml).preprocessor.blank.content`, defaulting to "".
local content = preprocessor:option("content", "");

-- Iterate through every chapter and set the contents to `content`.
for _, chapter in preprocessor:chapters() do
    chapter.content = content;
end

-- Submit our changes back to mdBook.
preprocessor:finish();
```

We can then add the following to `book.toml` to run our preprocessor:

```toml
[preprocessor.blank]
command = "lune run <path_to_blank>"
content = ""
```

### Writing Renderers

The following is an example renderer that prints word counts:

```luau
local mdbook = require(...);
local serde = require("@lune/serde");
local fs = require("@lune/fs");

-- Create the renderer. The 'name' string tells mdbook.luau where to look
-- for options, and what to use as a namespace in `:log()`.
local renderer = mdbook.Renderer.new("word_count");

-- Fetch the `(book.toml).output.word_count.split`, defaulting to " ".
local split = renderer:option("split", " ");

local word_counts = {
    total = 0,
};

-- Iterate through every chapter and tally word counts.
for _, chapter in renderer:chapters() do
    local word_count = #string.split(chapter.content, split);
    renderer:log("info", `{chapter.name}: {word_count}`);
    word_counts[chapter.name] = word_count;
    word_counts.total += word_count;
end

renderer:log("info", `total: {word_counts.total}`);
fs.writeFile(renderer:destination() .. "/word_count.json", serde.encode("json", word_counts));
```

We can then add the following to `book.toml` to run our renderer:

```toml
[output.word_count]
command = "lune run ../../<path_to_word_count>" # cwd is equal to `renderer:destination()`, so we gotta adjust accordingly
# split = "" # Count by letter instead
```
