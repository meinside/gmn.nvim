# gmn.nvim

[![ci](https://github.com/meinside/gmn.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/meinside/gmn.nvim/actions/workflows/ci.yml)

A Neovim plugin for generating texts using Google [Gemini APIs](https://ai.google.dev/gemini-api/docs/quickstart#rest).

## Requirements

- Neovim **0.10.0** or later (uses `vim.system`)
- `curl` available on `$PATH`

## Installation

### lazy.nvim

```lua
  -- default: ./lua/gmn/config.lua
  {
    "meinside/gmn.nvim",
    config = function()
      require("gmn").setup({
        -- (default values)
        configFilepath = "~/.config/gmn.nvim/config.json",
        timeout = 30 * 1000,
        model = "gemini-2.5-flash",
        safetyThreshold = "BLOCK_ONLY_HIGH",
        stripOutermostCodeblock = function()
          return vim.bo.filetype ~= "markdown"
        end,
        verbose = false,
      })
    end,
  },

```

## Configuration

Get your Google AI API key from [here](https://makersuite.google.com/app/apikey), then

### Environment Variable

Use an environment variable named `GEMINI_API_KEY` like:

```bash
# export your environment variable,
$ export GEMINI_API_KEY="AI0123456789-abcdefg-XYZW"

# create an .env file with your environment variable,
$ echo "GEMINI_API_KEY=AI0123456789-abcdefg-XYZW" > .env

# or, run nvim with your environment variable,
$ GEMINI_API_KEY="AI0123456789-abcdefg-XYZW" nvim
```

### Config File

Or, create a JSON config file at path `configFilepath` with the following content:

```json
{
  "api_key": "AI0123456789-abcdefg-XYZW"
}
```

## Usage (with command)

### Text Generation

#### Insert Generated Text At Current Cursor Position

![gmn-nvim insert-with-prompt](https://github.com/meinside/gmn.nvim/assets/185988/f0575fe1-b40d-4962-9cec-f22818635767)

Run following command with a prompt:

```
:GeminiGenerate <<your prompt text here>>
```

It will generate a text from your prompt and insert it at the current cursor position.

For generating with a prompt and google web search, use:

```
:GeminiGenerateWithSearch <<your prompt which needs some searched results from google>>
```

For generating with contents fetched from URLs in the prompt, use:

```
:GeminiGenerateWithURLFetch <<your prompt which does something with <https://url1>, <https://url2> ...>>
```

#### Generate Text With Selected Range As A Prompt

![gmn-nvim replace](https://github.com/meinside/gmn.nvim/assets/185988/aeb5aee1-0078-4407-9acd-e9628b519420)

Select a range of text with visual block, and run following command:

```
:'<,'>GeminiGenerate
```

then it will generate a text from the selected text as a prompt, and replace the range with the generated one.

For generating with the selected range and google web search, use:

```
:'<,'>GeminiGenerateWithSearch
```

For generating with contents fetched from URLs in the selected range, use:

```
:'<,'>GeminiGenerateWithURLFetch
```

#### Replace Selected Range With Generated Text

![gmn-nvim replace-with-prompt](https://github.com/meinside/gmn.nvim/assets/185988/831aa4f2-cfb9-4253-8cf6-e585b7617284)

Select a range of text with visual block, and run following command with a prompt:

```
:'<,'>GeminiGenerate your prompt text here
```

then it will generate a text from both the selected text and prompt, and replace the selected range with the generated one.

For generating with a prompt, selected range, and google web search, use:

```
:'<,'>GeminiGenerateWithSearch <<your prompt>>
```

For generating with a prompt and contents fetched from URLs in the selected range, use:

```
:'<,'>GeminiGenerateWithURLFetch <<your prompt>>
```


### Cancelling an In-Flight Request

If a generation is taking too long, cancel it with:

```
:GeminiCancel
```

Calling any `:GeminiGenerate*` command while another one is in flight also cancels the previous one.

### Git Commit Message Generation

#### Generate a Git Commit Message with Current Buffer

Run following command:

```
:GeminiGenerateGitCommitLog
```

then it will generate a commit message from the result of `git diff --staged`,

clear the current buffer, and insert the generated message.

#### Replace Selected Range With Generated Git Commit Message

Select a range of text with visual block, and run following command:

```
:'<,'>GeminiGenerateGitCommitLog
```

then it will generate a commit message from the selected range,

and replace the range with the generated one.

## Usage (with lua)

`generate_text` is asynchronous. Pass a callback to receive the result:

```lua
require("gmn").generate_text(
  { "hello, ", "how are you doing?" },
  function(parts, err)
    if err ~= nil then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    print(vim.inspect(parts))
  end,
  -- optional opts:
  -- { thinking = true, web_search = true, fetch_urls = true }
  {}
)
```

## Tests

The test suite has no external dependencies; run it with neovim:

```bash
# all tests
nvim --headless --clean -u NONE -l tests/run.lua

# filter by substring (e.g. only util specs)
nvim --headless --clean -u NONE -l tests/run.lua util
```

Each `tests/*_spec.lua` returns a table mapping test name to function.
The runner exits non-zero on failure, so it works as-is in CI.

## Todos / Improvements

- [X] Add screen recordings for text generation.
- [ ] Add screen recordings for git commit log generation.
- [X] Strip unwanted markdown codeblock around the generated texts.
- [X] Add an option for setting safety threshold.
- [X] Handle multiple content parts (skipping non-text and thought parts).
- [ ] Handle multiple candidates (would need a picker UI).
- [ ] Add nice UIs for comparing & applying generated texts.
- [X] Add tests.

## License

MIT

