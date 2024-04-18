{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        # https://github.com/rvaiya/keyd/blob/master/docs/keyd.scdoc
        extraConfig = ''
          # Emulate the Textblade layout
          # https://waytools.rocks/keyboards/maps/qwerty

          # the idea is to use layers to stay on the alpha keys as much as possible:
          # - space is the green layer, which has all the symbols and numbers
          # - chord DF and you switch to the edit layer, which has cursor keys and editing shortcuts
          #   - chord SDF and you add shift for selecting
          #   - add space for more navigation, search etc
          # - chord ASDF and you switch to the app layer, which has shortcuts for navigating
          # - the bottom row has mirrored chords for control, alt, meta and combinations
          # - KF is a macro layer, which adds all the modifiers, so you can use the left hand to define shortcuts

          ########### my general configuration ###########
          ### basic
          [global]
          # The keyboard layout
          default_layout = colemak
           
          # The time (in milliseconds) separating the initial execution of a macro sequence and the first repetition.
          # macro_timeout = 600

          # The time separating successive executions of a macro.
          # macro_repeat_timeout = 50

          # If set, this will turn the capslock light on whenever a layer is active.
          # Note: Some wayland compositors will aggressively toggle LED state rendering this option unusable.
          layer_indicator = 1

          # The maximum time between successive keys interpreted as part of a chord.
          # (default: 50)
          # chord_timeout = 

          # The length of time a chord must be held before being activated.
          # (default: 0)
          # chord_hold_timeout = 

          # If non-zero, timeout a oneshot layer activation after the supplied number of milliseconds.
          # (default: 0)
          oneshot_timeout = 500

          # If non-zero, ignore the tap behaviour of an overloaded key if it is held for the given number of miliseconds.
          # (default: 0).
          # overload_tap_timeout = 
          
          [colemak:layout]
          # standard colemak
          ; = o
          d = s
          e = f
          f = t
          g = d
          h = h
          i = u
          j = n
          k = e
          l = i
          n = k
          o = y
          p = ;
          r = p
          s = r
          t = g
          u = l
          y = j

          # make my intl keyboard less wide
          102nd = layer(shift)
          \ = enter
          [ = backspace
          ] = backspace
          tab = esc
          capslock = tab

          ########### TextBlade layers ###########
          ### basic
          [main]
          # stickiness
          shift = oneshot(shift)
          control = oneshot(control)
          leftalt = oneshot(alt)
          rightalt = oneshot(altgr)

          # modifier combos, bottom row
          z+x = layer(control)
          x+c = layer(alt)
          c+v = layer(meta)
          z+c = layer(controlalt)
          x+v = layer(altmeta)
          z+v = layer(controlmeta)

          m+, = layer(meta)
          ,+. = layer(alt)
          .+/ = layer(control)
          ,+/ = layer(controlalt)
          m+. = layer(altmeta)
          m+/ = layer(controlmeta)

          # layer toggles
          space = overload(green, space)
          k+l = layer(macros)
          d+f = layer(edit)
          a+s+d+f = layer(app)

          [shift]
          # capslock when two shifts are pressed or shift is tapped twice
          shift = capslock
          
          [controlalt:C-A]
          [controlmeta:C-M]
          [altmeta:A-M]
          
          ### green: lots of symbols within easy reach
          [green]
          tab = ~
          q = 1
          w = 2
          e = 3
          r = 4
          t = 5
          y = 6
          u = 7
          i = 8
          o = 9
          p = 0

          capslock = `
          a = !
          s = @
          d = #
          f = $
          g = %
          h = ^
          j = &
          k = *
          l = (
          ; = )

          leftshift = _
          102nd = _
          z = +
          x = -
          c = =
          v = {
          b = }
          n = [
          m = ]
          , = ;
          . = :
          / = \

          ### edit: cursor keys and editing shortcuts
          [edit]
          # add the ring finger for shift
          s = layer(shift)
          # go to app layer
          a+s = layer(app)

          i = up
          k = down
          j = left
          l = right

          . = end
          m = home
          u = C-left
          o = C-right
          
          # undo/redo (with s)
          ; = C-z
          # cut/copy/paste
          y = C-x
          h = C-c
          n = C-v
          # select all
          p = C-a
          
          # for vscode command palette
          , = C-p

          # "stronger" navigation
          [edit+green]
          i = pageup
          k = pagedown
          j = C-home
          l = C-end
          
          ## vscode
          # multi-cursor
          h = C-d
          n = C-k
          # find
          u = C-f
          
          ### app: navigation shortcuts
          # import Alt so that it's sticky between keypresses
          [app:A]
          ## home row: tabs
          # prev/next tab
          j = C-pageup
          l = C-pagedown
          # new tab
          h = C-t
          # close tab
          ' = C-w

          ## top row: windows
          # prev/next window of app
          u = S-A-`
          o = A-`
          # new window
          y = C-n
          # close window
          [ = A-w

          ## bottom row: apps
          # prev/next app
          m = S-A-tab
          . = A-tab
          # close app
          rightshift = A-q

          ## middle column: navigation
          # browser back/forward
          k = A-left
          i = A-right
          # open new browser tab via Global Tab Shortcuts extension
          , = S-A-s

          # Macro layer: we apply all modifiers for easy and non-clashing shortcut defining
          # use extensions like run-or-raise to define global application shortcuts
          [macros:M-A-C-S]
          space = swap(greenmacros)
          # green+macros don't get shift
          [greenmacros:M-A-C]
        '';
      };
    };
  };
}