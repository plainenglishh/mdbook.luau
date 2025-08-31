local stdio = require("@lune/stdio");
local datetime = require("@lune/datetime");

--[=[
    The overall configuration object for MDBook, essentially an in-memory 
    representation of `book.toml`.
]=]
export type Config = {
    --- Metadata about the book.
    read book: {
        --- The book's title.
        read title: string,

        --- The book's authors.
        read authors: {string},

        --- An optional description for the book.
        read description: string?,

        --- Location of the book source relative to the book's root directory.
        read src: string,

        --- Does this book support more than one language?
        read multilingual: boolean,

        --- The main language of the book.
        read language: string?,

        --- The direction of text in the book: Left-to-right (LTR) or Right-to-left (RTL).
        read ["text-direction"]: "ltr" | "rtl",
    },
    read build: {
        --- Where to put built artefacts relative to the book's root directory.
        read ["build-dir"]: string,

        --[=[
            Should non-existent markdown files specified in `SUMMARY.md` be created
            if they don't exist?
        ]=] 
        read ["create-missing"]: string,

        --[=[
            Should the default preprocessors always be used when they are
            compatible with the renderer?
        ]=]
        read ["use-default-preprocessors"]: boolean,

        --- Extra directories to trigger rebuild when watching/serving
        read ["extra-watch-dirs"]: {string},
    },
    read preprocessor: {[string]: any},
    read output: {[string]: any},
};

local common = {};

function common.read_stdin(): buffer
    return buffer.fromstring(stdio.readToEnd());
end

function common.write_stdout(out: string | buffer)
    stdio.write(if type(out) == "string" then out else buffer.tostring(out));
end

export type Level = "info" | "warn" | "error";

function common.log(namespace: string, level: Level, message: string)
    local now = datetime.now():toLocalTime();
    local message = string.format(
        "%04i-%02i-%02i %02i:%02i:%02i [%s] (%s): %s", 
        now.year, now.month, now.day,
        now.hour, now.minute, now.second,
        level:upper(), namespace, message);
    stdio.ewrite(message);
    stdio.ewrite("\n");
end

return common;
