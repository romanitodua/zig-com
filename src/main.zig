const zigwin32 = @import("zigwin32");
const std = @import("std");
const lib = @import("myzigprojects_lib");

const security_center = zigwin32.system.security_center;
const com = zigwin32.system.com;
const foundation = zigwin32.foundation;

pub fn main() !void {
    const hr_init = com.CoInitializeEx(null, com.COINIT_APARTMENTTHREADED);
    std.debug.print("The number is: {}\n", .{hr_init});
    defer com.CoUninitialize();

    var product_list: ?*security_center.IWSCProductList = null;
    var product: ?*security_center.IWscProduct = null;

    var bstr_val: ?foundation.BSTR = null;

    const err = com.CoCreateInstance(security_center.CLSID_WSCProductList, null, com.CLSCTX_INPROC_SERVER, security_center.IID_IWSCProductList, @ptrCast(&product_list));
    std.debug.print("err is: {}\n", .{err});

    const prListErr = product_list.?.Initialize(security_center.WSC_SECURITY_PROVIDER_FIREWALL);

    std.debug.print("prList err is: {}\n", .{prListErr});

    var product_count: i32 = 0;
    const countErr = product_list.?.get_Count(&product_count);

    std.debug.print("prList err is: {}\n", .{countErr});
    std.debug.print("count  is: {}\n", .{product_count});

    var i: u32 = 0;
    while (i < @as(u32, @intCast(product_count))) : (i += 1) {
        const itemErr = product_list.?.get_Item(i, &product);
        std.debug.print("itemErr  is: {}\n", .{itemErr});

        const nameErr = product.?.get_ProductName(&bstr_val);
        std.debug.print("name  is: {?}\n", .{bstr_val});
        std.debug.print("nameERR  is: {}\n", .{nameErr});

        const len = foundation.SysStringLen(bstr_val.?);
        const utf16_slice = @as([*]const u16, @ptrCast(bstr_val.?))[0..len];

        std.debug.print("\nProduct name: {s}\n", .{std.unicode.utf16LeToUtf8Alloc(
            std.heap.page_allocator,
            utf16_slice,
        ) catch "Unknown"});
        foundation.SysFreeString(bstr_val.?);

        var product_state: security_center.WSC_SECURITY_PRODUCT_STATE = undefined;
        const stateErr = product.?.get_ProductState(&product_state);

        std.debug.print("stateErr  is: {}\n", .{stateErr});

        const state_str = switch (product_state) {
            .ON => "On",
            .OFF => "Off",
            .SNOOZED => "Snoozed",
            .EXPIRED => "Expired",
        };
        std.debug.print("Product state: {s}\n", .{state_str});
    }
}
