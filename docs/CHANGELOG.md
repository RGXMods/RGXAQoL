# RGX | AQoL

## 2.1.10

- The options follow the RGX standard layout: General is the first tab and Automation the second, each a single column of full-width cards (Questing, Party and death, Vendors), the same as RGX Professions.
- Removed the description lines under the card titles so the options start right under the header and fit the cards.
- Removed the chat prefix box: the prefix is built into the framework's chat, which uses RGX | AQoL. Chat output and login message switches remain. Needs RGX-Framework 2.17.1.

## 2.1.9

- The options are two tabs: Automation (questing, vendors, party and death) and General. Nothing is automation on the General tab any more.
- The General tab is the framework's standard options card: minimap icon, Addons-menu entry, chat output, login message and chat prefix, the same on every RGX mod. Needs RGX-Framework 2.17.0.
- Switch labels and sliders no longer run into their ON/OFF text or values.
- Chat uses the shared prefix and respects the chat-output and login-message switches.
- AQoL has its own icon (RGX red ring with a plus) in the Addons list, panel and minimap button.
- Removed the "Use English language" setting and the reload button; the client language is always used.

## 2.1.8

- The minimap button and `/qol` open the options panel again. Both called a variable that was declared further down the file, so the click did nothing.
- The panel uses the RGX look: the RGX red ring with a light grey accent in the Material Round style, instead of pink.
- The minimap tooltip, the Addons menu entry and the first-run message read "RGX | AQoL".

## 2.1.7

- The options panel is now two tabs, Automation and Utilities, each a two-column card grid.
- AQoL targets WoW Forever only.
- Packaging: published to GitHub, CurseForge, Wago and WoWInterface from one tagged release.
- Removed third-party attribution text from the addon metadata and the project pages.
- Project pages now describe the addon as built in-house.
