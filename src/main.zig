/// Sample program for creating a window in Windows.

const std = @import("std");
const windows = std.os.windows;
const kernel = windows.kernel32;
const user32 = windows.user32;
const print = std.debug.print;

pub fn main() anyerror!void {
    // obtain module granted from Windows OS
    const module_handle = windows.kernel32.GetModuleHandleW(null) orelse {
        print("Error: Unable to obtain module handle\n", .{});
        return;
    };

    // convert module to HWND instance
    const hinstance = @ptrCast(windows.HINSTANCE, module_handle);

    // create window class
    const class_name = "WindowClassName";
    const window_class_info = user32.WNDCLASSEXA{
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
               print("quiting window\n", .{});
               return;
           },
           else => {
               print("Unhandled error\n", .{});
           }
        }
    }
}

const LParam = packed struct {
    x: i16,
    y: i16,
};

fn windowProc(hwnd: windows.HWND, uMsg: c_uint, wParam: usize, lParam: isize) callconv(windows.WINAPI) isize {
    switch(uMsg){
        user32.WM_NCCREATE => {
            print("before window creation step #1\n", .{});
            return user32.defWindowProcA(hwnd, uMsg, wParam, lParam);
        },
        user32.WM_CREATE => {
            print("before create #2\n", .{});
            return user32.defWindowProcA(hwnd, uMsg, wParam, lParam);
        },
        user32.WM_MOUSEMOVE => {
            // cast the lower 32-bits of lParam into x and y integers
            const mouseCoord = @ptrCast(*const LParam, &lParam);
            print("Mouse: {d},{d}\n", .{mouseCoord.x, mouseCoord.y});
        },
        user32.WM_PAINT => {
            // paint to screen here when needed.
            return user32.defWindowProcA(hwnd, uMsg, wParam, lParam);
        },
        user32.WM_CLOSE => {
            const quitInput = user32.messageBoxA(hwnd, "Really quit?", "My application", user32.MB_OKCANCEL) catch {
                print("Unable to get user input\n", .{});
                return user32.defWindowProcA(hwnd, uMsg, wParam, lParam);
            };

            if(quitInput == user32.IDOK){
                _ = user32.destroyWindow(hwnd) catch unreachable;
            }
            
            return 0;
        },
        user32.WM_DESTROY => {
            print("window about to be destroyed\n", .{});
            user32.postQuitMessage(0);
            return 0;
        },
        else => {
            return user32.defWindowProcA(hwnd, uMsg, wParam, lParam);
        }
    }
    
    return 0;
}