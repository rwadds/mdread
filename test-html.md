# HTML passthrough tests

Raw HTML is passed through as plain text — tags stripped, entities decoded —
except inside code, where it must stay exactly as written.

## An HTML block

<div class="callout">
  This whole block is raw HTML. The tags are stripped and the text kept.
</div>

## Inline HTML in prose

This sentence has <strong>bold</strong>, <em>italic</em>, and <code>code-ish</code>
tags that should all be stripped, leaving just the words behind.

## Line breaks from br tags

First line.<br>Second line after a br.<br/>Third line after a self-closing br.

## HTML entities

Named entities: &copy; &mdash; &hellip; &amp; &lt; &gt; &trade; &deg; &rsquo;

Numeric entities: &#169; and &#8212; and &#x2026;

## An HTML comment

<!-- This entire comment, and its text, should vanish from the output. -->

Text after the comment proves the comment was consumed cleanly.

## HTML inside code stays literal

Inline code such as `<div>` and `&amp;` must NOT be stripped or decoded — it
should display exactly as typed.

```
A fenced code block with <html> tags and &entities; is left completely alone.
```

## An autolink is not an HTML tag

A bare URL in angle brackets, <https://example.com>, is an autolink and should
become a clickable link rather than being stripped away.

## A nested HTML block

<table>
  <tr><td>Cell A</td><td>Cell B</td></tr>
</table>
