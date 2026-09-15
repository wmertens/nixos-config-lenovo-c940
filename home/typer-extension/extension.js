import Gio from 'gi://Gio';
import Clutter from 'gi://Clutter';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// Same as gnome-shell's on-screen keyboard: commit through the input method
// when the focused client supports text-input (all Wayland toolkits), else
// fall back to key events, which only cover keysyms in the current keymap.
const IFACE = `<node><interface name="org.wout.Typer">
  <method name="Type"><arg type="s" name="text" direction="in"/></method>
</interface></node>`;

export default class Typer extends Extension {
    enable() {
        this._dev = Clutter.get_default_backend().get_default_seat()
            .create_virtual_device(Clutter.InputDeviceType.KEYBOARD_DEVICE);
        this._dbus = Gio.DBusExportedObject.wrapJSObject(IFACE, this);
        this._dbus.export(Gio.DBus.session, '/org/wout/Typer');
    }

    disable() {
        this._dbus.unexport();
        this._dbus = null;
        this._dev = null;
    }

    Type(text) {
        if (Main.inputMethod.currentFocus) {
            Main.inputMethod.commit(text);
            return;
        }
        // ponytail: X11/Xwayland clients only get chars present in the keymap
        for (const ch of text) {
            const keyval = Clutter.unicode_to_keysym(ch.codePointAt(0));
            const t = Clutter.get_current_event_time() * 1000;
            this._dev.notify_keyval(t, keyval, Clutter.KeyState.PRESSED);
            this._dev.notify_keyval(t, keyval, Clutter.KeyState.RELEASED);
        }
    }
}
