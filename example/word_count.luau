local mdbook = require("@mdbook/");

local serde = require("@lune/serde");
local fs = require("@lune/fs");

local renderer = mdbook.Renderer.new("word_count");

local split = renderer:option("split", " ");

local word_counts = {
    total = 0,
};

for _, chapter in renderer:chapters() do
    local word_count = #string.split(chapter.content, split);
    renderer:log("info", `{chapter.name}: {word_count}`);
    word_counts[chapter.name] = word_count;
    word_counts.total += word_count;
end

renderer:log("info", `total: {word_counts.total}`);
fs.writeFile(renderer:destination() .. "/word_count.json", serde.encode("json", word_counts));