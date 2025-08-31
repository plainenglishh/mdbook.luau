local process = require("@lune/process")
local common = require("../common");
local json = require("../vendor/json");
local book = require("../book");

export type PreprocessorContext = {
    read root: string,
    read config: common.Config,
    read renderer: string,
    read mdbook_version: string,
};

export type PreprocessorSetup = {
    name: string,
    stdin: (string | buffer)?,
    renderers: {string}?,
};

export type Preprocessor = setmetatable<{
    _name: string,
    _context: PreprocessorContext,
    _book: book.Book,
}, {
    __index: getmetatable<Preprocessor>,

    new: (name_or_setup: string | PreprocessorSetup) -> Preprocessor,
    finish: (self: Preprocessor) -> (),

    book: (self: Preprocessor) -> book.Book,

    version: (self: Preprocessor) -> string,
    root: (self: Preprocessor) -> string,
    renderer: (self: Preprocessor) -> string,
    config: (self: Preprocessor) -> common.Config,
    
    chapters: (self: Preprocessor) -> (book.ChapterIter, {book.Chapter}, number),
    
    options: (self: Preprocessor) -> {[string]: any},
    option: (self: Preprocessor, name: string, default: any?) -> any,

    log: (self: Preprocessor, level: common.Level, message: string) -> (),
}>;

local Preprocessor = {};
Preprocessor.__index = Preprocessor;

function Preprocessor.new(name_or_setup: string | PreprocessorSetup): Preprocessor
    local setup: PreprocessorSetup = if type(name_or_setup) == "table" then name_or_setup else { name = name_or_setup };

    if process.args[1] == "supports" then
        if not setup.renderers then
            return process.exit(0);
        end

        local renderer = process.args[2];
        if not table.find(setup.renderers, renderer) then
            return process.exit(1);
        end

        return process.exit(0);
    end
    
    local raw = setup.stdin or common.read_stdin();
    local context: PreprocessorContext, raw_book: any = unpack(json.decode(raw) :: any);

    return setmetatable({
        _name = setup.name,
        _context = context,
        _book = book.decode(raw_book),
    }, Preprocessor);
end

function Preprocessor.finish(self: Preprocessor)
    common.write_stdout(book.encode(self._book));
end


function Preprocessor.book(self: Preprocessor): book.Book
    return self._book;
end

function Preprocessor.version(self: Preprocessor): string
    return self._context.mdbook_version;
end

function Preprocessor.root(self: Preprocessor): string
    return self._context.root;
end

function Preprocessor.renderer(self: Preprocessor): string
    return self._context.renderer;
end

function Preprocessor.config(self: Preprocessor): common.Config
    return self._context.config;
end

function Preprocessor.chapters(self: Preprocessor): (book.ChapterIter, {book.Chapter}, number)
    return book.chapters(self._book);
end

function Preprocessor.options(self: Preprocessor): {[string]: any}
    return self._context.config.preprocessor[self._name] or {};
end

function Preprocessor.option(self: Preprocessor, name: string, default: any?): any
    local options = self:options();
    local value = options[name];

    return if value == nil then default else value;
end

function Preprocessor.log(self: Preprocessor, level: common.Level, message: string)
    common.log(self._name, level, message);
end

return Preprocessor;
