---
title: "The Keyboard"
permalink: /input-output/keyboard
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

Before USB, keyboards and mice connected to the computer via the PS/2 connector. These were circular 6-pin ports, often coloured green and purple.

Most keyboards we use today connect to the computer via USB. Thus interacting with the keyboard should require us to first write a USB driver, a challenging task just to read keys.

USB drivers are large and complex. As keyboard input is often required in early stages of power-on, such as in the bootloader, the BIOS (specifically the System Management Mode firmware) can handle this for us, converting USB keyboard interaction into old-style PS/2. As a result, in order to enable use of the keyboard, we have the option to write a PS/2 keyboard driver, which is much simpler.

Before interacting with the USB host controller in your own USB driver, this legacy keyboard support must first be disabled. This can be done via the appropriate host controller interface (e.g. EHCI).
{: .notice--info}

## The PS/2 Controller

The IBM Personal System/2 introduced two purpose-built connectors (known as the PS/2 ports) for connecting compatible mice and keyboards. These connectors have a particular method of serial command-response communication.

<br/>
<img src="/assets/images/parts_2/ps-2-ports.jpg" alt="Example of PS/2 Connectors"/> <br/>
By <a title="User:Norm~commonswiki" href="//commons.wikimedia.org/wiki/User:Norm~commonswiki">Norman Rogers</a> - <span class="int-own-work" lang="en">Own work</span>, Public Domain, <a href="https://commons.wikimedia.org/w/index.php?curid=12584">Link</a>
<br/>

Both ports were co-ordinated by the PS/2 controller, a relativly powerful chip, which was also responsible for the A20 Gate and the system reset line, which could be used to restart the computer.

