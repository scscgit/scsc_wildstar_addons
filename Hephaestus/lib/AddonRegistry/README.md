# AddonRegistry


Utility library for Wildstar MMO

## Description
Allows addons that contain multiple sub-addons to register each component to allow modification of the component - applies mostly to Carbine addons.

This way an only slightly modified version of the base Addon can be created that allows external modifications without having to redistribute the whole base addon with any changes integrated into it. Ultimately prevents incompabilities and dependency/substitution collisions.


# How to use:

## Modifying existing addons:

Take Carbine's `Tradeskills` addon. This package contains four separate addons (`TradeskillTree`, `TradeskillSchematics`, `TradeskillTalents`, `TradeskillContainer`) that each register through `Apollo.RegisterAddon(self)` without supplying any name for the addon. By default the **package** name get's used in those cases, which leads to four addons registering themselves under the same name (here "`Tradeskills`"). 
The effect is that there is (almost) no way to access any of the component addons. Trying to get the component addons through `Apollo.GetAddon("Tradeskill[Tree|Schematics|Talents|Container]")` yields a `nil` result, and calling `Apollo.GetAddon("Tradeskills")` only get's the *last* component addon that registered itself. If that's not the one you want to modify you're out of luck.

Now, to allow access to the subcomponents perform these steps:
##### 1. Include package
Add `AddonRegistry.lua` to the package addon (In this guide I'll assume it get's stored in `Lib/AddonRegistry.lua`.
##### 2. Modify toc
Add a `<Script Name="Lib/AddonRegistry.lua"/>` entry to the addon's `toc.xml` file *before any other script or form entries*.
##### 3. Change addon registration
In each component addon's lua file, modify the call to `Apollo.RegisterAddon` (typically inside the `Init` method) as follows. Change
```lua
Apollo.RegisterAddon(self)
```
to
```lua
Apollo.RegisterAddon(self, nil, nil, {"DoctorVanGogh:Lib:AddonRegistry"})
```
##### 4. Perform registry registration
In each component addon's lua file, change (if necessary *add*) the `OnLoad` method and add this piece of code (preferably at the start):
```lua
local AddonRegistry = Apollo.GetPackage("DoctorVanGogh:Lib:AddonRegistry").tPackage
AddonRegistry:RegisterAddon(self, "[ADDONPACKAGE]", "[COMPONENTADDON]") 
```
Substitute `[ADDONPACKAGE]` & `[COMPONENTADDON]` with the appropriate names. In our example this would be `Tradeskills` for `[ADDONPACKAGE]` and `TradeskillTree`(, `TradeskillSchematics`, ...) for `[COMPONENTADDON]` respectively.
##### 5. Setup clean depencendies/replacements 
Change the Addon Properties to replace it's base version (here `Tradeskills`) and be nice and call the modified addon something similar (`CRBTradeskills`). That way an external dependency will still be able to look things up if the author is aware of this naming scheme.



## Getting access to the components:

Once again assume you want to change something for `Tradeskills`. In your distribution-package you should include the modified version of the base Addon from the previous step.
Now if you develop an Addon called `FooAddon` and want to modify for example `TradeskillTalents` then perform the following steps:
##### 1. Include package
Add `AddonRegistry.lua` to your FooAddon (In this guide I'll assume it get's stored in `Lib/AddonRegistry.lua`.
##### 2. Modify toc
Add a `<Script Name="Lib/AddonRegistry.lua"/>` entry to FooAddon's `toc.xml` file *before any other script or form entries*.
##### 3. Setup dependencies
In your FooAddon's call to `Apollo.RegisterAddon` be sure to include `"DoctorVanGogh:Lib:AddonRegistry"` *as well as* `Tradeskills` as dependencies:
```lua
Apollo.RegisterAddon(self, "FooAddon", bHasConfiguration, {"DoctorVanGogh:Lib:AddonRegistry", "CRBTradeskills"})
```
(Keep any other dependencies as needed)

##### 4. Access component addon
In your `FooAddon`'s `OnLoad` method (or at any later point in the addon lifetime) you can access the component addon through
```lua
local AddonRegistry = Apollo.GetPackage("DoctorVanGogh:Lib:AddonRegistry").tPackage
local tAddonTradeskillTalents = AddonRegistry:GetAddon("Tradeskills", "TradeskillTalents")
```
store & use this reference as you like


# Method list:

## RegisterAddon(tAddon, strContainer, strName)
Store an addon for later access in the registry

* *tAddon* - Addon you want to store a reference to
* *strContainer* - Name for the Addon-package whose components you want to store
* *strName* - Name for the component addon you want to store a reference to

## GetAddon(strContainer, strName)
Get a reference to a stored addon from the registry

* *strContainer* - Name for the Addon-package whose components you want to get
* *strName* - Name for the component addon you want to get a reference to

## AddonRegistry:GetAddons()
Gets all stored addons in the registry. Could be iterated with `pairs`, the key is a string in the format `[PACKAGENAME]:[COMPONENTNAME]`, the values are the respective addons.

