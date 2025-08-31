--- Framework for writing mdBook preprocessors and renderers with Lune.
local mdbook = {};

local Preprocessor = require("@self/classes/Preprocessor");
mdbook.Preprocessor = Preprocessor;
export type PreprocessorContext = Preprocessor.PreprocessorContext;

local Renderer = require("@self/classes/Renderer");
mdbook.Renderer = Renderer;
export type RenderContext = Renderer.RenderContext;


local book = require("@self/book");
mdbook.book = book;
export type Book = book.Book;
export type BookItem = book.BookItem;
export type Chapter = book.Chapter;
export type PartTitle = book.PartTitle;
export type Separator = book.Separator;

local common = require("@self/common");
export type Config = common.Config;

return mdbook;
