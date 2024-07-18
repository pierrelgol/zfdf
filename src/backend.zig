// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   backend.zig                                      :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/17 09:31:53 by pollivie          #+#    #+#             //
//   Updated: 2024/07/17 09:31:54 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const minilibx = @import("minilibx").mlx;
const Allocator = std.mem.Allocator;

pub const MlxBackend = struct {
    allocator: Allocator,
    mlx_ptr: ?*anyopaque,
    win_ptr: ?*anyopaque,
    img_ptr: ?*anyopaque,
    img_buffer: ?[*:0]i32,
    img_bpp: i32,
    img_size: i32,
    img_endian: i32,
    width: i32,
    height: i32,
    dwidth: usize,
    dheight: usize,

    pub fn init(allocator: Allocator, width: i32, height: i32, title: []const u8) !*MlxBackend {
        var self: *MlxBackend = try allocator.create(MlxBackend);
        self.*.allocator = allocator;
        self.*.mlx_ptr = null;
        self.*.win_ptr = null;
        self.*.img_ptr = null;
        self.*.img_buffer = null;
        _ = self.createMlx();
        _ = self.createWindow(width, height, title);
        _ = self.createImage(width, height);
        self.width = width;
        self.height = height;
        self.dwidth = (@intCast(width));
        self.dheight = (@intCast(height));
        return (self);
    }

    pub fn createMlx(self: *MlxBackend) bool {
        self.*.mlx_ptr = wrap_mlx_init();
        return (true);
    }

    pub fn createWindow(self: *MlxBackend, width: i32, height: i32, title: []const u8) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = self.destroyWindow();
            }
            self.*.win_ptr = wrap_mlx_new_window(self.*.mlx_ptr, width, height, @constCast(@alignCast(@ptrCast(title.ptr))));
            return (true);
        }
        return (false);
    }

    pub fn createImage(self: *MlxBackend, width: i32, height: i32) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.img_ptr) |_| {
                _ = self.destroyImage();
            }
            self.*.img_ptr = wrap_mlx_new_image(self.*.mlx_ptr, width, height);
            self.*.img_buffer = wrap_mlx_get_data_addr(self.*.img_ptr, &self.img_bpp, &self.img_size, &self.img_endian);
            return (true);
        }
        return (false);
    }

    pub fn destroyImage(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.img_ptr) |_| {
                _ = wrap_mlx_destroy_image(self.*.mlx_ptr, self.*.img_ptr);
                self.img_ptr = null;
                return (true);
            }
        }
        return (false);
    }

    pub fn clearWindow(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_clear_window(self.*.mlx_ptr, self.*.win_ptr);
                return (true);
            }
        }
        return (false);
    }

    pub fn clearImageBuffer(self: *MlxBackend) void {
        const height :usize = @intCast(self.height);
        const width :usize = @intCast(self.width);
        for (0..height) |h| {
            for (0..width) |w| {
                putPixelImage(self, @as(i32, @intCast(w)), @as(i32, @intCast(h)), 0x00_00_00_00);
            }
        }
    }

    pub fn destroyDisplay(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_destroy_display(self.*.mlx_ptr);
            return (true);
        }
        return (false);
    }

    pub fn destroyWindow(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_destroy_window(self.*.mlx_ptr, self.*.win_ptr);
                return (true);
            }
        }
        return (false);
    }

    pub fn createImageBuffer(self: *MlxBackend) bool {
        if (self.*.img_ptr) |_| {
            return (true);
        }
        return (false);
    }

    pub fn keyAutorepeatOn(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_do_key_autorepeaton(self.*.mlx_ptr);
            return (true);
        }
        return (false);
    }

    pub fn keyAutorepeatOff(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_do_key_autorepeatoff(self.*.mlx_ptr);
            return (true);
        }
        return (false);
    }

    pub fn doSync(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_do_sync(self.*.mlx_ptr);
            return (true);
        }
        return (false);
    }

    pub fn exposeHookOne(self: *MlxBackend, function_ptr: ?*const fn (arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) bool {
        if (self.*.win_ptr) |_| {
            _ = wrap_mlx_expose_hook_1(self.*.win_ptr, function_ptr, arg);
            return (true);
        }
        return (false);
    }

    pub fn exposeHookTwo(self: *MlxBackend, function_ptr: ?*const fn (keycode: i32, arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) bool {
        if (self.*.win_ptr) |_| {
            _ = wrap_mlx_expose_hook_2(self.*.win_ptr, function_ptr, arg);
            return (true);
        }
        return (false);
    }

    pub fn getColorValue(self: *MlxBackend, color: i32) i32 {
        if (self.*.mlx_ptr) |_| {
            const result = wrap_mlx_get_color_value(self.*.mlx_ptr, color);
            return (result);
        }
        return (0);
    }

    pub fn getScreenSize(self: *MlxBackend, width: *i32, height: *i32) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_get_screen_size(self.*.mlx_ptr, width, height);
            return (true);
        }
        return (false);
    }

    pub fn genericHookOne(self: *MlxBackend, x_event: i32, x_mask: i32, function_ptr: ?*const fn (arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) bool {
        if (self.*.win_ptr) |_| {
            _ = wrap_mlx_hook_1(self.*.win_ptr, x_event, x_mask, function_ptr, arg);
            return (true);
        }
        return (false);
    }

    pub fn genericHookTwo(self: *MlxBackend, x_event: i32, x_mask: i32, function_ptr: ?*const fn (keycode: i32, arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) bool {
        if (self.*.win_ptr) |_| {
            _ = wrap_mlx_hook_2(self.*.win_ptr, x_event, x_mask, function_ptr, arg);
            return (true);
        }
        return (false);
    }

    pub fn keyHookOne(self: *MlxBackend, function_ptr: ?*const fn (arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) bool {
        if (self.*.win_ptr) |_| {
            _ = wrap_mlx_key_hook_1(self.*.win_ptr, function_ptr, arg);
            return (true);
        }
        return (false);
    }

    pub fn keyHookTwo(self: *MlxBackend, function_ptr: ?*const fn (keycode: i32, arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) bool {
        if (self.*.win_ptr) |_| {
            _ = wrap_mlx_key_hook_2(self.*.win_ptr, function_ptr, arg);
            return (true);
        }
        return (false);
    }

    pub fn loopStart(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_loop(self.*.mlx_ptr);
            return (true);
        }
        return (false);
    }

    pub fn loopEnd(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_loop_end(self.*.mlx_ptr);
            return (true);
        }
        return (false);
    }

    pub fn loopHookOne(self: *MlxBackend, function_ptr: ?*const fn (arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_loop_hook_1(self.*.mlx_ptr, function_ptr, arg);
            return (true);
        }
        return (false);
    }

    pub fn loopHookTwo(self: *MlxBackend, function_ptr: ?*const fn (keycode: i32, arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) bool {
        if (self.*.mlx_ptr) |_| {
            _ = wrap_mlx_loop_hook_2(self.*.mlx_ptr, function_ptr, arg);
            return (true);
        }
        return (false);
    }

    pub fn getMousePos(self: *MlxBackend, x_pos: *i32, y_pos: *i32) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_mouse_get_pos(self.*.mlx_ptr, self.*.win_ptr, x_pos, y_pos);
                return (true);
            }
        }
        return (false);
    }

    pub fn setMousePos(self: *MlxBackend, x_pos: i32, y_pos: i32) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_mouse_move(self.*.mlx_ptr, self.*.win_ptr, x_pos, y_pos);
                return (true);
            }
        }
        return (false);
    }

    pub fn mouseHide(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_mouse_hide(self.*.mlx_ptr, self.*.win_ptr);
                return (true);
            }
            return (false);
        }
    }

    pub fn mouseShow(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_mouse_show(self.*.mlx_ptr, self.*.win_ptr);
                return (true);
            }
            return (false);
        }
    }

    pub fn putPixelImage(self: *MlxBackend, x: i32, y: i32, color: i32) void {
        const buffer = self.*.img_buffer orelse return;
        if ((x >= 0 and x < self.*.width) and (y >= 0 and y < self.*.height)) {
            const fx: usize = @intCast(x);
            const fy: usize = @intCast(y);
            buffer[fx + (fy * self.dwidth)] = color;
        }
    }

    pub fn putPixelRaw(self: *MlxBackend, x: i32, y: i32, color: i32) void {
        if ((x >= 0 and x < self.*.width) and (y >= 0 and y < self.*.height)) {
            wrap_mlx_pixel_put(self.*.mlx_ptr, self.*.win_ptr, x, y, color);
        }
    }

    pub fn putImageToWindow(self: *MlxBackend, x: i32, y: i32) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_put_image_to_window(self.*.mlx_ptr, self.*.win_ptr, self.*.img_ptr, x, y);
                return (true);
            }
        }
        return (false);
    }

    pub fn setFont(self: *MlxBackend, font_name: [*:0]u8) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_set_font(self.*.mlx_ptr, self.*.win_ptr, font_name[0..]);
                return (true);
            }
        }
        return (false);
    }

    pub fn stringPut(self: *MlxBackend, string: [*:0]u8, x: i32, y: i32) bool {
        if (self.*.mlx_ptr) |_| {
            if (self.*.win_ptr) |_| {
                _ = wrap_mlx_string_put(self.*.mlx_ptr, self.*.win_ptr, x, y, string[0..]);
                return (true);
            }
        }
        return (false);
    }

    pub fn destroyMlx(self: *MlxBackend) bool {
        if (self.*.mlx_ptr) |_| {
            std.c.free(self.*.mlx_ptr);
            return (true);
        }
        return (false);
    }

    pub fn deinit(self: *MlxBackend) void {
        const allocator = self.allocator;
        _ = self.destroyImage();
        _ = self.destroyWindow();
        _ = self.destroyDisplay();
        _ = self.destroyMlx();
        _ = allocator.destroy(self);
    }
};

extern fn wrap_mlx_clear_window(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_destroy_display(mlx_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_destroy_image(mlx_ptr: ?*anyopaque, img_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_destroy_window(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_do_key_autorepeatoff(mlx_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_do_key_autorepeaton(mlx_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_do_sync(mlx_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_expose_hook_1(win_ptr: ?*anyopaque, funct_ptr: ?*const fn (arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) i32;
extern fn wrap_mlx_expose_hook_2(win_ptr: ?*anyopaque, funct_ptr: ?*const fn (keycode: i32, arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) i32;
extern fn wrap_mlx_get_color_value(mlx_ptr: ?*anyopaque, color: i32) i32;
extern fn wrap_mlx_get_data_addr(img_handle: ?*anyopaque, img_bpp: *i32, img_size: *i32, img_endian: *i32) [*:0]i32;
extern fn wrap_mlx_get_screen_size(mlx_ptr: ?*anyopaque, size_x: *i32, size_y: *i32) i32;
extern fn wrap_mlx_hook_1(win_handle: ?*anyopaque, x_event: i32, x_mask: i32, callback: ?*const fn (?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) callconv(.C) i32;
extern fn wrap_mlx_hook_2(win_handle: ?*anyopaque, x_event: i32, x_mask: i32, callback: ?*const fn (i32, ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) callconv(.C) i32;
extern fn wrap_mlx_init() ?*anyopaque;
extern fn wrap_mlx_key_hook_1(win_ptr: ?*anyopaque, funct_ptr: ?*const fn (arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) i32;
extern fn wrap_mlx_key_hook_2(win_ptr: ?*anyopaque, funct_ptr: ?*const fn (keycode: i32, arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) i32;
extern fn wrap_mlx_loop(mlx_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_loop_end(mlx_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_loop_hook_1(mlx_ptr: ?*anyopaque, funct_ptr: ?*const fn (?*anyopaque) callconv(.C) i32, param: ?*anyopaque) callconv(.C) i32;
extern fn wrap_mlx_loop_hook_2(mlx_ptr: ?*anyopaque, funct_ptr: ?*const fn (i32, ?*anyopaque) callconv(.C) i32, param: ?*anyopaque) callconv(.C) i32;
extern fn wrap_mlx_mouse_get_pos(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque, x: *i32, y: *i32) i32;
extern fn wrap_mlx_mouse_hide(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_mouse_hook_1(win_ptr: ?*anyopaque, funct_ptr: ?*const fn (arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) i32;
extern fn wrap_mlx_mouse_hook_2(win_ptr: ?*anyopaque, funct_ptr: ?*const fn (keycode: i32, arg: ?*anyopaque) callconv(.C) i32, arg: ?*anyopaque) i32;
extern fn wrap_mlx_mouse_move(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque, x: i32, y: i32) i32;
extern fn wrap_mlx_mouse_show(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque) i32;
extern fn wrap_mlx_new_image(mlx_ptr: ?*anyopaque, width: i32, height: i32) ?*anyopaque;
extern fn wrap_mlx_new_window(mlx_ptr: ?*anyopaque, size_x: i32, size_y: i32, title: [*:0]u8) ?*anyopaque;
extern fn wrap_mlx_pixel_put(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque, x: i32, y: i32, color: i32) i32;
extern fn wrap_mlx_put_image_to_window(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque, img_ptr: ?*anyopaque, x: i32, y: i32) i32;
extern fn wrap_mlx_set_font(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque, name: [*:0]u8) void;
extern fn wrap_mlx_string_put(mlx_ptr: ?*anyopaque, win_ptr: ?*anyopaque, x: i32, y: i32, string: [*:0]u8) i32;
extern fn wrap_mlx_xpm_file_to_image(mlx_ptr: ?*anyopaque, filename: [*:0]u8, width: *i32, height: *i32) ?*anyopaque;
extern fn wrap_mlx_xpm_to_image(mlx_ptr: ?*anyopaque, filename: *[*:0]u8, width: *i32, height: *i32) i32;
