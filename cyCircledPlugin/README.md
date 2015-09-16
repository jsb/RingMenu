# cyCircled Plugin

The cyCircled AddOn allows to customize the appearance of action buttons of numerous third-party AddOns. In order to enable cyCircled skinning for RingMenu, you need to install a plugin file, which is provided here.

![SprocketBlack](http://i.imgur.com/M4ognuj.png)
![Glossy](http://i.imgur.com/V8zzUaK.png)
![Serenity](http://i.imgur.com/zF62uAr.png)

## Plugin Installation

1. Copy the **RingMenu.lua** file provided in this folder (WoW/Interface/AddOns/RingMenu/cyCircledPlugin) into the **plugins** subfolder of the cyCircled AddOn (e.g., WoW/Interface/AddOns/cyCircled/plugins)
2. Open the **cyCircled.toc** file (located at WoW/Interface/AddOns/cyCircled/cyCircled.toc) with a text editor (e.g. Notepad, TextEdit). Near the bottom, you'll see a list of lines looking like
        
        plugins\XXX.lua
        
   Just below that, add the following new line:
        
        plugins\RingMenu.lua
        
   Save the file and re-start your WoW Client.
