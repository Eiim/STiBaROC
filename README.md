# STiBaROC
A STiBaRC client for the OpenComputers Minecraft mod

**Warning: STiBaROC is currently beta. As such, it lacks features, and may be very buggy.**
**If you do come across any bugs, be sure to open an issue!**

## What is STiBaRC?

[STiBaRC](https://stibarc.com/) is a small social media network, created by @herronjo. You can see its source [here](https://github.com/STiBaRC/stibarc_web).

STiBaROC is one of a couple clients for STiBaRC which allow you to use STiBaRC, which also include [STiBaRC Native](https://play.google.com/store/apps/details?id=com.stibarc.mobile). STiBaROC is by far the least practical current client, however.

## How do I install this?

First, you'll need to install OpenComputers using a recent build from the https://ci.cil.li/. As of writing, the releases on CurseForge **do not** work, as they do not include the newer buffer functionality used to improve scrolling preformance.

Then, you'll need a top-tier computer: tier 3 case, tier 3 screen, internet card, and a tier 3 graphics card. A tier 3 CPU and tier 3.5 RAM are preferable. As always, you'll also need a flashed EEPROM, install floppy, power source, and keyboard. More setup info can be found on the [OpenComputers wiki](https://ocdoc.cil.li/tutorial:oc1_basic_computer).

To install STiBaROC, for now, run `wget cdn.jsdelivr.net/gh/rxi/json.lua/json.lua` and `wget cdn.jsdelivr.net/gh/Eiim/STiBaROC/stibaroc.lua`. You should then be able to run `stibaroc` from your home directory.

## How do I use this?

There's not a lot to do right now, but you can click on posts to view them, and then click on the STiBaRC logo to return to the front page. **It may take a long time to load!** Have patience when loading, especially with posts. Post rendering is currently poorly optimized. It should improve in the near-ish future. If you're from the far-ish future, why not fix it yourself and open a PR?

## Do you intend to support STiBaROC?

Yes, in that I'll try to fix any significant bugs that come up, but I don't know how many features I'll add. I don't expect it will have full support, especially as things like images, audio, and video aren't exactly well-supported in OpenComputers. It will probably end up supporting more than it currently does.
