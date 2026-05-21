# A Quiet Place to Read

A small Markdown file you can drop into **mdread** to feel how the typography behaves.

## Why serifs?

When you read for any length of time, a *humanist serif* is a friend to the eye. Each letter has a little more shape — entry strokes, exit strokes, a roof on the lowercase `r` — and your eye tracks the rhythm rather than the pixels.

That's why Apple drew **New York** specifically for long-form reading on its platforms. It is the typeface we lean on here.

### A short list of small joys

- Generous line height
- A column that doesn't stretch past about 70 characters
- Code that sits politely in a tinted box, not shouting
- Quiet headings that still feel like *headings*

### And the numbered cousin

1. Open a file with `⌘O`
2. Or drag a `.md` onto the window
3. Resize the text with `⌘+`, `⌘-`, `⌘0`
4. Reload after editing externally with `⌘R`

## A blockquote, because we have to

> The best reader is the one who reads slowly. He weighs each word, he stops, he reflects, he questions, he resumes his reading.
>
> — *Nicolas Boileau*

## A bit of code

Inline like `let x = 42` blends with the text. A fenced block stands apart:

```swift
struct Reader: View {
    let blocks: [MarkdownBlock]

    var body: some View {
        ScrollView {
            ForEach(blocks.indices, id: \.self) { i in
                BlockView(block: blocks[i])
            }
        }
    }
}
```

```
Plain code blocks work too — no language hint required.
```

---

### Links and emphasis

Visit [Anthropic](https://www.anthropic.com) for more. Inline emphasis comes in *italic*, **bold**, and even ***both***. You can also ~~strike things through~~ when you change your mind.

## What else mdread renders

A few newer arrivals, each earning its place on the page.

### Tables

| Construct      | Mnemonic    |        Added |
| -------------- | :---------: | -----------: |
| Tables         | rows & keys |     this one |
| Nested lists   | indentation | the next one |
| Task lists     | `[x]`       |   just below |

Columns can lean left, sit centred, or align to the right.

### Lists within lists

- Typography
  - A humanist serif for the body text
  - Monospace kept to code, where it earns its keep
- Layout
  1. A column measured to the eye
  2. Line height with room to breathe

### A list that keeps score

- [x] Render tables
- [x] Nest one list inside another
- [x] Tick a box
- [ ] Read every book ever written

An old-fashioned heading
------------------------

That underline — a row of dashes beneath a line of text — is a *Setext*
heading, the quieter cousin of the `#` form.

### A little raw HTML

Markdown lets you drop in <strong>raw HTML</strong>, and mdread keeps the
words while quietly setting the tags aside.

<div align="center">
  Even a whole block of HTML becomes plain, readable text.
</div>

### An image

![A photograph, by way of Lorem Picsum](https://picsum.photos/seed/mdread/720/240)

###### A whisper of a heading

That's all for now. Drop a real file in to keep reading.
