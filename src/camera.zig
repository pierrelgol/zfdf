// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   camera.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/18 10:39:43 by pollivie          #+#    #+#             //
//   Updated: 2024/07/18 10:39:44 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const fdf_type = @import("type.zig");
const Vec3 = fdf_type.Vec3;
const DEG_2_RAD = std.math.deg_per_rad;

pub const CameraControl = enum {
    move_left,
    move_right,
    move_up,
    move_down,
    move_forward,
    move_backward,

    pitch_up,
    pitch_down,
    yaw_right,
    yaw_left,
    roll_right,
    roll_left,

    zoom_in,
    zoom_out,

    scale_in,
    scale_out,
};

pub const Camera = struct {
    bak_position: Vec3,
    bak_rotation: Vec3,
    bak_zoom_lvl: f32,
    bak_scal_lvl: f32,
    position: Vec3,
    rotation: Vec3,
    zoom_lvl: f32,
    scal_lvl: f32,

    pub fn init(position: Vec3, rotation: Vec3, zoom_lvl: f32, scale_lvl: f32) Camera {
        return Camera{
            .bak_position = position,
            .bak_rotation = rotation,
            .bak_zoom_lvl = zoom_lvl,
            .bak_scal_lvl = scale_lvl,
            .position = position,
            .rotation = rotation,
            .zoom_lvl = zoom_lvl,
            .scal_lvl = scale_lvl,
        };
    }

    pub inline fn reset(camera: *Camera) void {
        camera.position = camera.bak_position;
        camera.rotation = camera.bak_rotation;
        camera.zoom_lvl = camera.bak_zoom_lvl;
        camera.scal_lvl = camera.bak_scal_lvl;
        camera.debug_log();
    }

    pub inline fn move(camera: *Camera, command: CameraControl, amount: f32) void {
        const movement_offset: Vec3 = switch (command) {
            CameraControl.move_left => Vec3{ .x = -amount, .y = 0, .z = 0 },
            CameraControl.move_right => Vec3{ .x = amount, .y = 0, .z = 0 },
            CameraControl.move_up => Vec3{ .x = 0, .y = -amount, .z = 0 },
            CameraControl.move_down => Vec3{ .x = 0, .y = amount, .z = 0 },
            CameraControl.move_forward => Vec3{ .x = 0, .y = 0, .z = -amount },
            CameraControl.move_backward => Vec3{ .x = 0, .y = 0, .z = amount },
            else => return,
        };
        camera.*.position = camera.*.position.add(movement_offset);
        // camera.debug_log();
    }

    pub inline fn rotate(camera: *Camera, command: CameraControl, amount: f32) void {
        const movement_offset: Vec3 = switch (command) {
            CameraControl.pitch_up => Vec3{ .x = -amount, .y = 0, .z = 0 },
            CameraControl.pitch_down => Vec3{ .x = amount, .y = 0, .z = 0 },
            CameraControl.yaw_right => Vec3{ .x = 0, .y = -amount, .z = 0 },
            CameraControl.yaw_left => Vec3{ .x = 0, .y = amount, .z = 0 },
            CameraControl.roll_right => Vec3{ .x = 0, .y = 0, .z = -amount },
            CameraControl.roll_left => Vec3{ .x = 0, .y = 0, .z = amount },
            else => return,
        };
        camera.*.rotation = camera.*.rotation.add(movement_offset);
        // camera.debug_log();
    }

    pub inline fn zoom(camera: *Camera, command: CameraControl, amount: f32) void {
        const zoom_offset: f32 = switch (command) {
            CameraControl.zoom_in => amount,
            CameraControl.zoom_out => -amount,
            else => return,
        };
        if ((camera.zoom_lvl + zoom_offset) >= 100.0)
            return;
        if ((camera.zoom_lvl + zoom_offset) <= 1.0)
        {
            if ((camera.zoom_lvl - 0.1) <= 0.0)
                return;
            camera.*.zoom_lvl -= 0.01;
            return;
        }
        camera.*.zoom_lvl += zoom_offset;
        // camera.debug_log();
    }

    pub inline fn scale(camera: *Camera, command: CameraControl, amount: f32) void {
        const scale_offset: f32 = switch (command) {
            CameraControl.scale_in => amount,
            CameraControl.scale_out => -amount,
            else => return,
        };
        if ((camera.scal_lvl + scale_offset) >= 100.0)
            return;
        if ((camera.scal_lvl + scale_offset) <= -100.0)
            return;
        camera.*.scal_lvl += scale_offset;
        // camera.debug_log();
    }

    pub inline fn getPositition(camera: *const Camera) Vec3 {
        return (camera.position);
    }

    pub inline fn getCosRotations(camera: *const Camera) Vec3 {
        const rad_x_cos: f32 = @cos(camera.rotation.x / DEG_2_RAD);
        const rad_y_cos: f32 = @cos(camera.rotation.y / DEG_2_RAD);
        const rad_z_cos: f32 = @cos(camera.rotation.z / DEG_2_RAD);
        return (Vec3{ .x = rad_x_cos, .y = rad_y_cos, .z = rad_z_cos });
    }

    pub inline fn getSinRotations(camera: *const Camera) Vec3 {
        const rad_x_cos: f32 = @sin(camera.rotation.x / DEG_2_RAD);
        const rad_y_cos: f32 = @sin(camera.rotation.y / DEG_2_RAD);
        const rad_z_cos: f32 = @sin(camera.rotation.z / DEG_2_RAD);
        return (Vec3{ .x = rad_x_cos, .y = rad_y_cos, .z = rad_z_cos });
    }

    pub inline fn getZoomLvl(camera : *const Camera) f32 {
        return camera.zoom_lvl;
    }

    pub inline fn getScaleLvl(camera : *const Camera) f32 {
        return camera.scal_lvl;
    }

    pub fn debug_log(camera: *Camera) void {
        std.log.debug("CAMERA", .{});
        std.log.debug("position = [{}|{}|{}]", .{ camera.position.x, camera.position.y, camera.position.z });
        std.log.debug("rotation = [{}|{}|{}]", .{ camera.rotation.x, camera.rotation.y, camera.rotation.z });
        std.log.debug("zoom_lvl = {}", .{camera.zoom_lvl});
        std.log.debug("scal_lvl = {}", .{camera.scal_lvl});
    }
};
