# Table tests

Exercises GitHub-style tables: alignment, optional outer pipes, ragged rows,
inline formatting in cells, escaped pipes, and horizontal scrolling.

## Basic table

| Name | Role     |
| ---- | -------- |
| Ada  | Pioneer  |
| Alan | Theorist |

## Column alignment — left, centre, right

| Left       | Centre      | Right |
| :--------- | :---------: | ----: |
| start      | middle      | end   |
| a          | bb          | ccc   |

## Without outer pipes

Name   | Score
------ | ----:
Tea    | 9
Coffee | 11

## Ragged rows — too few and too many cells are normalised

| A        | B   | C     |
| -------- | --- | ----- |
| only one |
| one      | two |
| one      | two | three | four |

## Inline formatting and code inside cells

| Syntax       | Renders as                  |
| ------------ | --------------------------- |
| `**bold**`   | **bold**                    |
| `*italic*`   | *italic*                    |
| `` `code` `` | `code`                      |
| `[link]()`   | [a link](https://example.com) |

## Escaped pipes inside cells

| Expression    | Meaning            |
| ------------- | ------------------ |
| `a \| b`      | a OR b             |
| `x \| y \| z` | three alternatives |

## A wide table — scrolls horizontally

| One | Two | Three | Four | Five | Six | Seven | Eight | Nine | Ten |
| --- | --- | ----- | ---- | ---- | --- | ----- | ----- | ---- | --- |
| 1   | 2   | 3     | 4    | 5    | 6   | 7     | 8     | 9    | 10  |

## A single-column table

| Just one column |
| --------------- |
| Row one         |
| Row two         |

## A pipe in prose is not a table

This sentence contains a | pipe character but is followed by ordinary text,
so it must stay a plain paragraph.
