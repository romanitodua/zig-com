const zigwin32 = @import("zigwin32");
const std = @import("std");
const lib = @import("myzigprojects_lib");

const security_center = zigwin32.system.security_center;
const com = zigwin32.system.com;
const foundation = zigwin32.foundation;


pub fn main() !void {
    const provider = security_center.WSC_SECURITY_PROVIDER_ANTIVIRUS;
    const hr_init = com.CoInitializeEx(null, com.COINIT_APARTMENTTHREADED);
    std.debug.print("The number is: {}\n", .{hr_init});
    defer com.CoUninitialize();

    var product_list: ?*security_center.IWSCProductList = null;
    var product: ?*security_center.IWscProduct2 = null;

    var bstr_val: ?foundation.BSTR = null;

    const err = com.CoCreateInstance(security_center.CLSID_WSCProductList, null, com.CLSCTX_INPROC_SERVER, security_center.IID_IWSCProductList, @ptrCast(&product_list));
    std.debug.print("err is: {}\n", .{err});

    const prListErr = product_list.?.Initialize(provider);

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
        bstr_val = null;

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

        if (provider != security_center.WSC_SECURITY_PROVIDER_FIREWALL) {
            var signature_status: security_center.WSC_SECURITY_SIGNATURE_STATUS = undefined;
            const sigErr = product.?.get_SignatureStatus(&signature_status);

            std.debug.print("sigErr  is: {}\n", .{sigErr});

            const status_str = switch (signature_status) {
                .UP_TO_DATE => "Up-to-date",
                .OUT_OF_DATE => "Out-of-date",
            };
            std.debug.print("Product status: {s}\n", .{status_str});
        }

        const remediationPathErr = product.?.get_RemediationPath(&bstr_val);
        std.debug.print("remediationPathErr  is: {}\n", .{remediationPathErr});

        const pathLen = foundation.SysStringLen(bstr_val.?);
        const pathSlice = @as([*]const u16, @ptrCast(bstr_val.?))[0..pathLen];

        std.debug.print("\n Remediation Path: {s}\n", .{std.unicode.utf16LeToUtf8Alloc(
            std.heap.page_allocator,
            pathSlice,
        ) catch "Unknown"});

        foundation.SysFreeString(bstr_val.?);
        bstr_val = null;

        if (provider == security_center.WSC_SECURITY_PROVIDER_ANTIVIRUS) {
            const timeStampErr = product.?.get_ProductStateTimestamp(&bstr_val);
            std.debug.print("timeStamp(AntivirusONly)  is: {}\n", .{timeStampErr});

            const timesTampLen = foundation.SysStringLen(bstr_val.?);
            const timestampSlice = @as([*]const u16, @ptrCast(bstr_val.?))[0..timesTampLen];

            std.debug.print("\n: {s}\n", .{std.unicode.utf16LeToUtf8Alloc(
                std.heap.page_allocator,
                timestampSlice,
            ) catch "Unknown"});
            foundation.SysFreeString(bstr_val);
            bstr_val = null;
        }
    }
}
