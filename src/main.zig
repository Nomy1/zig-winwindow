const std = @import("std");
const windows = std.os.windows;
const user32 = windows.user32;

pub fn main() anyerror!void {
    // obtain module granted from Windows OS
    const module_handle = windows.kernel32.GetModuleHandleW(null) orelse {
        std.debug.print("Unable to obtain module handle", .{});
        return;
    };

    // convert module to HWND instance
    const hinstance = @ptrCast(windows.HINSTANCE, module_handle);

    // create window class
    const class_name = "WindowClassName";
    const window_class_info = windows.user32.WNDCLASSEXA{
        .style = user32.CS_OWNDC | user32.CS_HREDRAW | user32.CS_VREDRAW,
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = @sizeOf(usize),
        .hInstance = hinstance,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = class_name,
        .hIconSm = null,
    };

    // register window class
    _ = try user32.registerClassExA(&window_class_info);
    defer user32.unregisterClassA(class_name, hinstance) catch {};

    // create window parameters
    var style: u32 = 0;
    style += @as(u32, user32.WS_VISIBLE);
    style += @as(u32, user32.WS_CAPTION | user32.WS_MAXIMIZEBOX | user32.WS_MINIMIZEBOX | user32.WS_SYSMENU);
    style += @as(u32, user32.WS_SIZEBOX);

    var rect = windows.RECT{ .left = 0, .top = 0, .right = 300, .bottom = 300 };
    _ = try user32.adjustWindowRectEx(&rect, style, false, 0);

    const x = user32.CW_USEDEFAULT;
    const y = user32.CW_USEDEFAULT;
    const w = user32.CW_USEDEFAULT;
    const h = user32.CW_USEDEFAULT;

    // create window
    const window_title = "My Window";
    const hwnd = try user32.createWindowExA(0, class_name, window_title, style, x, y, w, h, null, null, hinstance, null);

    // show window
    _ = user32.showWindow(hwnd, user32.SW_SHOWNORMAL);

    // initialize message event struct
    var msg: user32.MSG = .{
        .hWnd = hwnd,
        .message = 0,
        .wParam = 0,
        .lParam = 0,
        .time = 0,
        .pt = .{.x = 0, .y = 0},
        .lPrivate = 0,
    };

    // main loop
    while (true) {
        // process message events (blocking)
        if(user32.getMessageA(&msg, null, 0, 0)) {
            _ = user32.translateMessage(&msg);
            _ = user32.dispatchMessageA(&msg);
        } else |err| switch(err) {
           error.Quit => {
               std.debug.print("quit", .{});
               return;
           },
           else => {
               std.debug.print("error!", .{});
           }
        }
    }
}

 fn windowProc(hwnd: windows.HWND, uMsg: c_uint, wParam: usize, lParam: isize) callconv(windows.WINAPI) isize {
    switch(uMsg){
        user32.WM_CLOSE => {
            _ = user32.destroyWindow(hwnd) catch unreachable;
            std.debug.print("try to quit", .{});
        },
        else => {
            return user32.defWindowProcA(hwnd, uMsg, wParam, lParam);
        }
    }
    
    return 0;
 }