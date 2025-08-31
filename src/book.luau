local json = require("./vendor/json");

--[=[
    The representation of a "chapter", usually mapping to a single file on
    disk however it may contain multiple sub-chapters.
]=]
export type Chapter = {
    --- A nested chapter.
    kind: "chapter",

    --- The chapter's name.
    name: string,

    --- The chapter's contents.
    content: string,

    --- The chapter's section number, if it has one.
    number: {number}?,

    --- Nested items.
    sub_items: {BookItem},

    --[=[
        The chapter's location, relative to the `SUMMARY.md` file.

        **Note**: After the index preprocessor runs, any README files will be
        modified to be `index.md`. If you need access to the actual filename
        on disk, use [`Chapter.source_path`] instead.

        This is `nil` for a draft chapter.
    ]=]
    path: string?,

    --[=[
        The chapter's source file, relative to the `SUMMARY.md` file.
        
        **Note**: Beware that README files will internally be treated as
        `index.md` via the [`Chapter.path`] field. The `source_path` field
        exists if you need access to the true file path.
        
        This is `None` for a draft chapter, or a synthetically generated
        chapter that has no file on disk.
    ]=]
    source_path: string?,

    --[=[
        An ordered list of the names of each chapter above this one in the 
        hierarchy.
    ]=]
    parent_names: {string},
};

--- A section separator.
export type Separator = {
    --- A section separator.
    kind: "separator",
};

--- A part title.
export type PartTitle = {
    --- A part title.
    kind: "part_title",

    --- The part title.
    title: string,
};

--- Enum representing any type of item which can be added to a book.
export type BookItem = Chapter | Separator | PartTitle;

--- A dumb tree structure representing a book.
export type Book = {
    --- The sections in this book.
    sections: {BookItem},
};

--[=[
    Module for decoding, encoding and manipulating `Book` instances.
]=]
local book = {};

--[=[
    Decodes a table or buffer into a `Book`.
]=]
function book.decode(raw: {[any]: any} | string | buffer): Book
    local raw: any = 
        if type(raw) == "table" then raw
        else json.decode(raw);

    local function decode_book_item(book_item: any): BookItem
        if book_item == "Separator" then 
            return { kind = "separator" };
        elseif book_item.Chapter then
            local sub_items: {BookItem} = {};

            for i: number, sub_item in book_item.Chapter.sub_items do
                sub_items[i] = decode_book_item(sub_item);
            end

            return {
                kind = "chapter",
                name = book_item.Chapter.name :: string,
                content = book_item.Chapter.content :: string,
                number = book_item.Chapter.number :: {number}?,
                sub_items = sub_items,
                path = book_item.Chapter.path :: string?,
                source_path = book_item.Chapter.source_path :: string?,
                parent_names = book_item.Chapter.parent_names :: {string},
            };
        elseif book_item.PartTitle then
            return { kind = "part_title", title = book_item.PartTitle :: string }
        else
            error("unknown book item");
        end
    end

    local sections: {BookItem} = {};
    for i: number, section in raw.sections do
        sections[i] = decode_book_item(section);
    end

    return {
        sections = sections
    };
end

function book.encode(book: Book): buffer
    local function encode_book_item(book_item: BookItem): any
        if book_item.kind == "separator" then
            return "Separator";
        elseif book_item.kind == "part_title" then
            return { PartTitle = book_item.title };
        elseif book_item.kind == "chapter" then
            local sub_items = {};
            for i, book_item in book_item.sub_items do
                sub_items[i] = encode_book_item(book_item);
            end
            
            return {
                Chapter = {
                    name = book_item.name,
                    content = book_item.content,
                    number = json.set_json_type(book_item.number, "array"),
                    sub_items = json.set_json_type(sub_items, "array"),
                    path = book_item.path,
                    source_path = book_item.source_path,
                    parent_names = json.set_json_type(book_item.parent_names, "array"),
                },
            };
        else
            error(`invalid book_item {book_item.kind}`);
        end
    end
    
    local sections = {};
    for i, book_item in book.sections do
        sections[i] = encode_book_item(book_item);
    end

    local raw_book = {
        sections = json.set_json_type(sections, "array"),
        __non_exhaustive = json.null,
    };

    return json.encode(raw_book, { pretty = false });
end

local function list_chapters(book: Book): {Chapter}
    local chapters = {};

    local function recurse(items: {BookItem})
        for _, item in items do
            if item.kind ~= "chapter" then
                continue;
            end

            table.insert(chapters, item);
            recurse(item.sub_items);
        end
    end

    recurse(book.sections);

    return chapters;
end

local function chapter_iter(chapters: {Chapter}, i: number): (number, Chapter)
    i += 1;
    local chapter = chapters[i];
    if not chapter then
        return nil :: any;
    end

    return i, chapter;
end

export type ChapterIter = ({Chapter}, number) -> (number, Chapter);

--[=[
    Iterate over a `Book`s chapters.
]=]
function book.chapters(book: Book): (ChapterIter, {Chapter}, number)
    return chapter_iter, list_chapters(book), 0;
end

return book;