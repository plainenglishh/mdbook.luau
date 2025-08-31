local mdbook = require("@mdbook/");

local renderer = mdbook.Renderer.new({
    name = "word_count",
});

local split_char = renderer:option("split", " ");

for _, chapter in renderer:chapters() do
    local word_count = #string.split(chapter.content, split_char);
    renderer:log("info", `{chapter.name}: {word_count}`)
end
