# MenuSupport

Simply plugin loader for iOS system menu. APIs designed easy to migration from ActionMenu.

## What's the difference with ActionMenu

### Protocol

Named as `MSMenuItem`. It have almost same property.

| MenuSupport     | ActionMenu            |
| --------------- | --------------------- |
| SEL action      | SEL action            |
| SEL canPerform  | SEL canPerform        |
| NSString *title | NSString *title       |
| UIImage *image  | UIImage *image        |
| N/A             | AMMenuItemStyle style |
| N/A             | NSInteger priority    |

### Plugin registration API.

Registration API has `ms_` prefix.

| MenuSupport                             | ActionMenu                                 |
| --------------------------------------- | ------------------------------------------ |
| **ms_**registerAction:title:canPerform: | registerAction:title:canPerform:           |
| N/A                                     | registerAction:title:canPerform:forPlugin: |

### Textual API for UIResponder

Textual API has `ms_` prefix without cached APIs.

| MenuSupport                          | ActionMenu                          |
| ------------------------------------ | ----------------------------------- |
| **ms_**textualRepresentation         | textualRepresentation               |
| **ms_**selectedTextualRepresentation | selectedTextualRepresentation       |
| N/A                                  | cachedTextualRepresentation         |
| N/A                                  | cachedSelectedTextualRepresentation |
| N/A                                  | actionMenuBehaviors                 |
| N/A                                  | always                              |

### UIAlertView API

UIAlertView is deprecated from iOS 8, not provide API for it.

### Preference key


| key              | MenuSupport                              | ActionMenu                                 |
| ---------------- | ---------------------------------------- | ------------------------------------------ |
| defaults         | **jp.r-plus.MenuSupport**                | com.booleanmagic.ActionMenu                |
| key              | **MS**PluginEnabled-<PluginName\>        | AMPluginEnabled-<PluginName\>              |
| PostNotification | **jp.r-plus.MenuSupport**.settingschange | com.booleanmagic.ActionMenu.settingschange |

### Install path

| MenuSupport                      | ActionMenu                  |
| -------------------------------- | --------------------------- |
| /Library/**MenuSupport**/Plugins | /Library/ActionMenu/Plugins |