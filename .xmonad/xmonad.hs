--
-- ~/.xmonad/xmonad.hs
--

--
-- Compiler options
--

{-# OPTIONS_GHC -Wno-deprecations -v #-}

--
-- Imports
--

import qualified Data.Map as M
import qualified XMonad.StackSet as W
import Data.Maybe (maybe)
import Graphics.X11.ExtraTypes.XF86
import System.Directory
import System.IO
import System.Posix.Env (getEnv)
import XMonad
import XMonad.Actions.CycleWS
import qualified XMonad.Actions.DynamicWorkspaceOrder as DO
import XMonad.Actions.PhysicalScreens
import XMonad.Config.Desktop
import XMonad.Config.Gnome
import XMonad.Config.Kde
import XMonad.Config.Xfce
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
import XMonad.Hooks.InsertPosition (insertPosition, Focus(Newer), Position(End), Position(Above))
import XMonad.Hooks.ManageHelpers
import XMonad.Layout.CenteredMaster
import XMonad.Layout.Grid
import XMonad.Layout.NoBorders
import XMonad.Layout.ResizableTile
import XMonad.Layout.Spacing
import XMonad.Layout.Spiral
import XMonad.Layout.ThreeColumns
import XMonad.Util.EZConfig
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.Scratchpad
import XMonad.Util.SpawnOnce
import XMonad.Util.WorkspaceCompare

--
-- basic configuration
--

myModMask = mod1Mask -- use the alt key as mod

myBorderWidth = 0 -- set window border size

myTerminal = "konsole" -- preferred terminal emulator

--
-- key bindings
--

myKeys =
  [ ((myModMask, xK_a), sendMessage MirrorShrink), -- for  ResizableTall
    ((myModMask, xK_z), sendMessage MirrorExpand), -- for  ResizableTall
    -- selecting particular monitors
    ((myModMask, xK_w), viewScreen def 0),
    ((myModMask, xK_e), viewScreen def 1),
    ((myModMask, xK_r), viewScreen def 2),
    ((myModMask, xK_j), windows W.focusUp),
    ((myModMask, xK_k), windows W.focusDown),
    -- cycling through workspaces in multi monitor setup
    ((myModMask .|. mod5Mask, xK_h), prevHiddenNonEmptyNoSPWS),
    ((myModMask, xK_Left), prevHiddenNonEmptyNoSPWS),
    ((myModMask .|. mod5Mask, xK_l), nextHiddenNonEmptyNoSPWS),
    ((myModMask, xK_Right), nextHiddenNonEmptyNoSPWS),
    ((myModMask, xK_o), scratchPad),
    ((myModMask, xK_p), spawn "krunner --replace"),
    ((myModMask, xK_F2), spawn "krunner --replace"),
    --, ((myModMask, xK_o), spawn "qdbus org.kde.plasmashell /PlasmaShell activateLauncherMenu") --uncomment this and comment the next line if you are not using latte-dock
    ((myModMask, xK_o), spawn "qdbus org.kde.lattedock /Latte activateLauncherMenu"),
    ((myModMask, xK_F1), spawn "qdbus org.kde.lattedock /Latte activateLauncherMenu"),
    ((myModMask, xK_j), windows W.focusUp),
    ((myModMask, xK_k), windows W.focusDown),
    ((myModMask .|. shiftMask, xK_j), windows W.swapUp),
    ((myModMask .|. shiftMask, xK_k), windows W.swapDown),
    ((myModMask, xK_t), withFocused $ windows . W.sink),
    ((myModMask, xK_space), sendMessage NextLayout)
  ]
  where
    scratchPad = scratchpadSpawnActionTerminal myTerminal
    getSortByIndexNoSP = fmap (. scratchpadFilterOutWorkspace) getSortByIndex
    prevHiddenNonEmptyNoSPWS = windows . W.greedyView =<< findWorkspace getSortByIndexNoSP Prev HiddenNonEmptyWS 1
    nextHiddenNonEmptyNoSPWS = windows . W.greedyView =<< findWorkspace getSortByIndexNoSP Next HiddenNonEmptyWS 1

--
-- hooks for newly created windows
-- note: run 'xprop WM_CLASS' to get className
--

myManageHook :: ManageHook
myManageHook = manageDocks <+> manageScratchPad <+> coreManageHook

coreManageHook :: ManageHook
coreManageHook =
  composeAll . concat $
    [ [className =? c --> doFloat | c <- myFloats],
      [className =? c --> insertPosition Above Newer | c <- myFloats],
      [className =? c --> hasBorder False | c <- myNonBorder],
      [isFullscreen --> doFullFloat],
      [fmap not willFloat --> insertPosition End Newer],
      [willFloat --> insertPosition Above Newer]
    ]
  where
    myFloats =
      [ "MPlayer",
        "Gimp",
        "Plasma-desktop",
        "plasmashell",
        "krunner",
        "Klipper",
        "Keepassx",
        "latte-dock",
        "lattedock",
        "conky-semi",
        "TeamViewer",
        "teamviewer",
        "ksmserver-logout-greeter",
        "euroscope.exe"
      ]
    myNonBorder =
      [ "latte-dock",
        "lattedock",
        "Plasma-desktop",
        "plasmashell",
        "krunner",
        "Klipper",
        "keepassx",
        "conky-semi",
        "ksmserver-logout-greeter"
      ]

-- yakuake style hook
manageScratchPad :: ManageHook
manageScratchPad = scratchpadManageHook (W.RationalRect l t w h)
  where
    h = 0.4 -- terminal height, 40%
    w = 0.9 -- terminal width, 90%
    t = 1 - h -- distance from top edge, 90%
    l = 1 - w -- distance from left edge, 5%

--
-- startup hooks
--

myStartupHook = do
  setWMName "LG3D"
  spawnOnce "picom"

--
-- layout hooks
--

myLayoutHook = spacing 10 $ avoidStruts $ coreLayoutHook

coreLayoutHook = Full ||| tiled ||| Mirror tiled ||| Grid ||| centerMaster Grid
  where
    -- default tiling algorithm partitions the screen into two panes
    tiled = ResizableTall nmaster delta ratio []
    -- The default number of windows in the master pane
    nmaster = 1
    -- Percent of screen to increment by when resizing panes
    delta = 1 / 200
    -- Default proportion of screen occupied by master pane
    ratio = 2 / 3

--
-- desktop :: DESKTOP_SESSION -> desktop_configuration
--

desktop "gnome" = gnomeConfig
desktop "xmonad-gnome" = gnomeConfig
desktop "kde" = kde4Config
desktop "kde-plasma" = kde4Config
desktop "plasma" = kde4Config
desktop "xfce" = xfceConfig
desktop _ = desktopConfig

--
-- main function (no configuration stored there)
--

main :: IO ()
main = do
  session <- getEnv "DESKTOP_SESSION"
  let defDesktopConfig = maybe desktopConfig desktop session
      myDesktopConfig =
        kde4Config
          { modMask = myModMask,
            borderWidth = myBorderWidth,
            focusedBorderColor = "#000000",
            normalBorderColor = "#000044",
            startupHook = myStartupHook,
            layoutHook = myLayoutHook,
            manageHook = myManageHook <+> manageHook defDesktopConfig,
            workspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
          }
          `additionalKeys` myKeys
  do xmonad myDesktopConfig
