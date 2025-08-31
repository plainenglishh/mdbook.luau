local book = require("../book");
local common = require("../common");
local json = require("../vendor/json");

--[=[
    The context provided to all renderers.
]=]
export type RenderContext = {
    --[=[
        Which version of `mdbook` did this come from (as written in `mdbook`'s
        `Cargo.toml`). Useful if you know the renderer is only compatible with
        certain versions of `mdbook`.
    ]=]
    version: string,

    --[=[
        The book's root directory.
    ]=]
    root: string,

    --[=[
        A loaded representation of the book itself.
    ]=]
    book: book.Book,

    --[=[
        The loaded configuration file.
    ]=]
    config: common.Config,

    --[=[
        Where the renderer *must* put any build artefacts generated. To allow
        renderers to cache intermediate results, this directory is not
        guaranteed to be empty or even exist.
    ]=]
    destination: string,
};

export type RendererSetup = {
    name: string,
    stdin: (string | buffer)?,
};

export type Renderer = setmetatable<{
    _name: string,
    _context: RenderContext,
}, {
    __index: getmetatable<Renderer>,

    new: (name_or_setup: string | RendererSetup) -> Renderer,
    
    book: (self: Renderer) -> book.Book,

    version: (self: Renderer) -> string,
    root: (self: Renderer) -> string,
    destination: (self: Renderer) -> string,
    config: (self: Renderer) -> common.Config,

    chapters: (self: Renderer) -> (book.ChapterIter, {book.Chapter}, number),

    options: (self: Renderer) -> {[string]: any},
    option: (self: Renderer, name: string, default: any?) -> any,

    log: (self: Renderer, level: common.Level, message: string) -> (),
}>;

local Renderer = {};
Renderer.__index = Renderer;

function Renderer.new(name_or_setup: string | RendererSetup): Renderer
    local setup: RendererSetup = if type(name_or_setup) == "table" then name_or_setup else { name = name_or_setup };

    local raw = setup.stdin or common.read_stdin();
    local context = json.decode(raw, { preserve_table_types = false }) :: RenderContext;
    context.book = book.decode(context.book :: any);

    return setmetatable({
        _name = setup.name,
        _context = context,
    }, Renderer);
end

function Renderer.book(self: Renderer): book.Book
    return self._context.book;
end

function Renderer.version(self: Renderer): string
    return self._context.version;
end

function Renderer.root(self: Renderer): string
    return self._context.root;
end

function Renderer.destination(self: Renderer): string
    return self._context.destination;
end

function Renderer.config(self: Renderer): common.Config
    return self._context.config;
end

function Renderer.chapters(self: Renderer): (book.ChapterIter, {book.Chapter}, number)
    return book.chapters(self._context.book);
end

function Renderer.options(self: Renderer): {[string]: any}
    return self._context.config.output[self._name] or {};
end

function Renderer.option(self: Renderer, name: string, default: any?): any
    local options = self:options();
    local value = options[name];

    return if value == nil then default else value;
end

function Renderer.log(self: Renderer, level: common.Level, message: string)
    common.log(self._name, level, message);
end

return Renderer;
