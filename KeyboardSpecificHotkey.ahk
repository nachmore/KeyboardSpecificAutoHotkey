/*
------------------------------------------------------------
 
USEFUL FUNCTIONS
 
------------------------------------------------------------
*/

KEYBD_RegisterHotkey(make_code, vendor_id, product_id, callback) {
  global _keybd_hotkeys, _keybd_registered

  _keybd_hotkeys[make_code] := { "callback": Func(callback)
    , "vendor_id": vendor_id
    , "product_id": product_id}

  if (not _keybd_registered) {
    return KEYBD_StartListening()
  }
  
  return 0
}

KEYBD_ShowDebugGui(enable_debug_gui := true) {
  global

  _keybd_debug_gui := enable_debug_gui
}

/*
 * Check %ErrorLevel% if this functions returns -1
 */
KEYBD_StartListening() {
  global 

  ; explicitly create an hwnd for this script to run on and store the hwnd in "ScriptHwnd"
  ; not sure if this inteferes with existing Gui (doesn't seem to), if so may need to move
  ; back to WinExist which wasn't as reliable
  Gui, +HwndScriptHwnd

  ; Register for keyboard inputs
  ; Usage Page = 1 & Usage = 6
  if (AHKHID_Register(1, 6, ScriptHwnd, RIDEV_INPUTSINK) == -1) {
    return -1
  }

  ;Intercept WM_INPUT
  OnMessage(0x00FF, "OnInputMsg")

  _ahkhid_registered := true

  if (_keybd_debug_gui) {
      Gui +LastFound -Resize -MaximizeBox -MinimizeBox

      Gui, Add, Text, x6 y10 w650 h40, Use the below to identify key presses and the devices making them, then translate these into calls to KEYBD_RegisterHotkey(make_code, vendor_id, product_id)

      Gui, Font, w700 s8, Courier New
      Gui, Add, ListBox, x6 y50 w650 h320 vlbxInput hwndhlbxInput,

      Gui, Show, , Keyboard Specific Hotkeys: Live Keyboard Codes
  }
}

/*
------------------------------------------------------------
 
Internal Goo
 
------------------------------------------------------------
*/

#include AHKHID.ahk

; Private variables
_keybd_hotkeys := {}
_keybd_debug_gui := false
_keybd_registered := false

; WM_INPUT Callback
OnInputMsg(wParam, lParam) {
  local r
  Critical    ;Or otherwise you could get ERROR_INVALID_HANDLE

  ;Get device type
  r := AHKHID_GetInputInfo(lParam, II_DEVTYPE) 

  If (r = -1) {
    OutputDebug %ErrorLevel%
  } Else If (r = RIM_TYPEKEYBOARD) {

    h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
    make_code := AHKHID_GetInputInfo(lParam, II_KBD_MAKECODE)


    if (_keybd_hotkeys[make_code]) {

      vendor_id := AHKHID_GetDevInfo(h, DI_HID_VENDORID, True)
      product_id := AHKHID_GetDevInfo(h, DI_HID_PRODUCTID, True)

      if (_keybd_hotkeys[make_code].vendor_id == vendor_id and _keybd_hotkeys[make_code].product_id == product_id) {
        _keybd_hotkeys[make_code].callback()
      }

    }
    
    if (_keybd_debug_gui) {
      GuiControl,, lbxInput, % ""
      . " make_code: "    AHKHID_GetInputInfo(lParam, II_KBD_MAKECODE)
      . " vendor_id: "   AHKHID_GetDevInfo(h, DI_HID_VENDORID, True)
      . " product_id: "  AHKHID_GetDevInfo(h, DI_HID_PRODUCTID, True)
      . " Flags: "       AHKHID_GetInputInfo(lParam, II_KBD_FLAGS)
      . " VKey: "        AHKHID_GetInputInfo(lParam, II_KBD_VKEY)
      . " Message: "     AHKHID_GetInputInfo(lParam, II_KBD_MSG) 
      . " ExtraInfo: "   AHKHID_GetInputInfo(lParam, II_KBD_EXTRAINFO)

      SendMessage, 0x018B, 0, 0,, ahk_id %hlbxInput%
      SendMessage, 0x0186, ErrorLevel - 1, 0,, ahk_id %hlbxInput%
    }
  }
}
