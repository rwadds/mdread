# Image tests

Exercises inline images and image blocks. Remote images need a network
connection; a failed fetch or an unreadable local file should fall back to a
tidy placeholder card rather than breaking the layout.

## Image block — remote

![A remote photograph](https://picsum.photos/seed/mdread-1/720/280)

## Image block — with a title (the title becomes the caption)

![Short alt text](https://picsum.photos/seed/mdread-2/720/240 "A title in quotes is shown as the caption")

## Image block — no alt text at all

![](https://picsum.photos/seed/mdread-3/640/200)

## Broken remote image — expect the placeholder

![This file does not exist](https://example.com/definitely-missing-9f3a.png)

## Local image — usually sandboxed out, expect the placeholder

A relative path resolves against this file's folder, but the App Sandbox
generally cannot read files sitting next to the document:

![A neighbouring diagram](./diagram.png)

## Inline image — splits the surrounding prose

A line of prose, then ![an image mid-sentence](https://picsum.photos/seed/mdread-4/240/240)
and the sentence continues afterwards on its own line.

## Two images in a single paragraph

![left](https://picsum.photos/seed/mdread-5/300/170) ![right](https://picsum.photos/seed/mdread-6/300/170)

## An angle-bracketed destination

![Bracketed URL](<https://picsum.photos/seed/mdread-7/420/200>)
