local mdbook = require("@mdbook/");

local preprocessor = mdbook.Preprocessor.new("image");

local image = preprocessor:option("image", "https://i.imgur.com/Q13Xwac.png");
local alt = preprocessor:option("alt", "alt");


for _, chapter in preprocessor:chapters() do
    chapter.content = `![{alt}]({image})`;
end

preprocessor:finish();
