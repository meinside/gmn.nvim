# gmn.nvim

A Neovim plugin for generating texts using Google [Gemini APIs](https://ai.google.dev/gemini-api/docs/quickstart#rest).

## Installation

### lazy.nvim

```lua

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
    dependencies = { { "nvim-lua/plenary.nvim" } },
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


### Git Commit Message Generation

#### Generate a Git Commit Message with Current Buffer

Run following command:

```
:GeminiGenerateGitCommitLog
```

then it will generate a commit message from the result of `git diff HEAD`,

clear the current buffer, and insert the generated message.

#### Replace Selected Range With Generated Git Commit Message

Select a range of text with visual block, and run following command:

```
:'<,'>GeminiGenerateGitCommitLog
```

then it will generate a commit message from the selected range,

and replace the range with the generated one.

## Usage (with lua)

```lua
local generated, err = require("gmn").generate_text({ "hello, ", "how are you doing?" })
if err == nil then
  print(vim.inspect(generated))
end
```

## Todos / Improvements

- [X] Add screen recordings for text generation.
- [ ] Add screen recordings for git commit log generation.
- [X] Strip unwanted markdown codeblock around the generated texts.
- [ ] Add nice UIs for comparing & applying generated texts.
- [X] Add an option for setting safety threshold.
- [ ] Handle multiple number of candidates and content parts.

## License

MIT

