import qualified Data.Map as M
import XMonad
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.EwmhDesktops ( fullscreenEventHook
				 , ewmh
				 )
import XMonad.Hooks.DynamicLog

main = xmonad =<< statusBar myBar myPP toggleStrutsKey myConfig

-- Command to launch the bar.
myBar = "xmobar"

-- Custom PP, configure it as you like. It determines what is being written to the bar.
myPP = xmobarPP { ppCurrent = xmobarColor "#429942" "" . wrap "<" ">" }

toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

myKeys x = M.union (M.fromList (newKeys x)) (keys defaultConfig x)

newKeys conf@(XConfig {XMonad.modMask = modMask}) = 
	[
		((0, 0x1008ff06 ), spawn "kbdlight down")
		, ((0, 0x1008ff05 ), spawn "kbdlight up") 
		, ((0, 0x1008ff03 ), spawn "light -Us sysfs/backlight/mba6x_backlight 10") 
		, ((0, 0x1008ff02 ), spawn "light -As sysfs/backlight/mba6x_backlight 10")
		, ((0, 0x1008ff12 ), spawn "amixer -q sset Master toggle")  
		, ((0, 0x1008ff11 ), spawn "amixer -q sset Master 5%-") 
		, ((0, 0x1008ff13 ), spawn "amixer -q sset Master 5%+")
	]

myConfig = def { terminal = "alacritty"
	, modMask = mod4Mask
	, keys = myKeys
}
