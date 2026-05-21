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

###### A whisper of a heading

That's all for now. Drop a real file in to keep reading.
