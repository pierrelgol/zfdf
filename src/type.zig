// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   type.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/17 10:53:09 by pollivie          #+#    #+#             //
//   Updated: 2024/07/17 10:53:10 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Order = std.math.Order;
const white = 0xFF_FF_FF_FF;

pub const Color = struct {
    color: i32,

    pub inline fn init(hexcolor: i32) i32 {
        var result: i32 = 0;
        result |= (hexcolor & 0x00_FF_00_00) >> 16;
        result |= (hexcolor & 0x00_00_FF_00);
        result |= (hexcolor & 0x00_00_00_FF) << 16;
        return result;
    }

    pub inline fn initFromHexToRGBA(hexcolor: i32) Color {
        var result: Color = undefined;
        result.color = 0;
        result.color |= (hexcolor & 0xFF0000) >> 16;
        result.color |= (hexcolor & 0x00FF00);
        result.color |= (hexcolor & 0x0000FF) << 16;
        return result;
    }
};

pub const Pixel = struct {
    x: i32,
    y: i32,
    color: i32,

    pub inline fn init(x: i32, y: i32, color: ?i32) Pixel {
        return Pixel{
            .x = x,
            .y = y,
            .color = color orelse white,
        };
    }
};

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub inline fn init(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub inline fn add(v0: Vec3, v1: Vec3) Vec3 {
        return Vec3{
            .x = (v0.x + v1.x),
            .y = (v0.y + v1.y),
            .z = (v0.z + v1.z),
        };
    }

    pub inline fn sub(v0: Vec3, v1: Vec3) Vec3 {
        return Vec3{
            .x = (v0.x - v1.x),
            .y = (v0.y - v1.y),
            .z = (v0.z - v1.z),
        };
    }

    pub inline fn mul(v0: Vec3, v1: Vec3) Vec3 {
        return Vec3{
            .x = (v0.x * v1.x),
            .y = (v0.y * v1.y),
            .z = (v0.z * v1.z),
        };
    }

    pub inline fn mulScalar(v0: Vec3, scalar: f32) Vec3 {
        return Vec3{
            .x = v0.x * scalar,
            .y = v0.y * scalar,
            .z = v0.z * scalar,
        };
    }

    pub inline fn rotX(v0: Vec3, cos_theta: f32, sin_theta: f32) Vec3 {
        return Vec3{
            .x = v0.x,
            .y = v0.y * cos_theta - v0.z * sin_theta,
            .z = v0.y * sin_theta + v0.z * cos_theta,
        };
    }

    pub inline fn rotY(v0: Vec3, cos_theta: f32, sin_theta: f32) Vec3 {
        return Vec3{
            .x = v0.x * cos_theta + v0.z * sin_theta,
            .y = v0.y,
            .z = -v0.x * sin_theta + v0.z * cos_theta,
        };
    }

    pub inline fn rotZ(v0: Vec3, cos_theta: f32, sin_theta: f32) Vec3 {
        return Vec3{
            .x = v0.x * cos_theta - v0.y * sin_theta,
            .y = v0.x * sin_theta + v0.y * cos_theta,
            .z = v0.z,
        };
    }

    pub inline fn rotXYZ(v0: Vec3, cos_thetas: Vec3, sin_thetas: Vec3) Vec3 {
        var result = rotX(v0, cos_thetas.x, sin_thetas.x);
        result = rotY(result, cos_thetas.y, sin_thetas.y);
        result = rotZ(result, cos_thetas.z, sin_thetas.z);
        return (result);
    }

    pub inline fn divScalar(v0: Vec3, scalar: f32) Vec3 {
        const inverse = if (scalar == 0) 1.0 else 1.0 / scalar;
        return (v0.mulScalar(inverse));
    }

    pub inline fn div(v0: Vec3, v1: Vec3) Vec3 {
        const inverse = v1.inv();
        return (v0.mul(inverse));
    }

    pub inline fn inv(v0: Vec3) Vec3 {
        return Vec3{
            .x = if (v0.x != 0.0) 1.0 / v0.x else 1.0,
            .y = if (v0.y != 0.0) 1.0 / v0.y else 1.0,
            .z = if (v0.z != 0.0) 1.0 / v0.z else 1.0,
        };
    }

    pub inline fn cmp(v0: Vec3, v1: Vec3) Order {
        const sum0 = v0.x + v0.y + v0.z;
        const sum1 = v1.x + v1.y + v1.z;
        if (sum0 < sum1)
            return Order.lt
        else if (sum0 > sum1)
            return Order.gt
        else
            return Order.eq;
    }
};
