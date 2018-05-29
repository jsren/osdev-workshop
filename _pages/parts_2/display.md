---
title: "Display (VGA)"
permalink: /input-output/display
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

1. Explain display pipeline

## Introduction

Like with the keyboard, there are two ways of working with the graphics card. The first is via the legacy "VGA" memory-mapped framebuffer. The second is to write drivers for communicating directly with the card via PCI Express.

Unfortunately, as is often the story with device manufacturers, the necessary specifications detailing how to communicate with the cards are not publicly available.

While this has been the case for [a long time](https://youtu.be/iYWzMvlj2RQ), it is increasingly possible to find documentation for integrated graphics devices, so some accelerated graphics options may be possible.
{: .notice--info}

This leaves us with the legacy VGA method. The bad news here is that this comes with many constraints, particularly on display resolution, and is the slowest method for drawing to the screen.

The good news is that the legacy VGA method is considerably simpler, and is possible to implement relatively quickly.

## VGA Memory

VGA memory is present in two ranges, the first is for Text Mode, where the memory is an array of characters, and the second is for Graphics Mode, where the memory is an array of pixel colours.

| Memory | Location |
| ------ | -------- |
| Text Mode | 0xB8000 - 0xBF000| |
| Graphics Mode | 0xA0000 - 0xAF000 |

## Text Mode

| Bits | Description |
| ---- | ----------- |
| 0-7 | ASCII character |
| 8 - 11 | Foreground Colour |
| 12 - 15 | Background Colour |

| Value | Colour | Value | Colour |
| ----- | ------ | ----- | ------ |
| 0x0 | Black | 0x8 | Dark Grey |
| 0x1 | Blue | 0x9 | Light Blue |
| 0x2 | Green | 0xA | Light Green |
| 0x3 | Cyan | 0xB | Light Cyan |
| 0x4 | Red | 0xC | Light Red |
| 0x5 | Magenta | 0xD | Light Magenta |
| 0x6 | Brown | 0xE | Yellow |
| 0x7 | Grey | 0xF | White |

```c
typedef struct
{
    unsigned foreground : 4;
    unsigned background : 4;
} __attribute__((packed)) vga_colour;

typedef struct
{
    uint8_t character;
    vga_colour colour;
} __attribute__((packed)) cell;
```

## Basic Display Algorithms

### Maintaining Position

Cursor (width and height).

### Clearing the Screen

To clear the screen, or a portion of the screen, simply write either a space character ` ` (in Text Mode) or a pixel with the desired background colour (in Graphics Mode) to the range of screen required.

### Line Drawing (Graphics Mode)

1. Representations
1. Naiive
1. Anti-aliasing

### 
