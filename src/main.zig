const zigwin32 = @import("zigwin32");
const std = @import("std");
const lib = @import("myzigprojects_lib");

const security_center = zigwin32.system.security_center;
const com = zigwin32.system.com;
const foundation = zigwin32.foundation;

pub const SecurityProduct = extern struct {
    ptype: i32,
    name: [*]u16,
    state: i32,
    signatureStatus: i32,
    timeStamp: ?[*]u16,
    remediationPath: ?[*]u16,
};

// pub fn main() !void {
//     const t = getSecurityProducts();

//     std.debug.print("HERE COMES THE OUTPUTTTT AARRAY {s}", .{"sds"});

//     var i: usize = 0;
//     while (true) {
//         const product = t[i];
//         if (i == 3) break;

//         std.debug.print("\nProduct {d}:\n", .{i + 1});
//         std.debug.print("type: {d}\n", .{product.type});

//         // const name = std.mem.span(product.name);
//         // std.debug.print("name: {s}\n", .{name});

//         // std.debug.print("state: {d}\n", .{product.state});
//         // std.debug.print("signatureStatus: {d}\n", .{product.signatureStatus});

//         // if (product.timeStamp) |timestamp| {
//         //     std.debug.print("timeStamp: {s}\n", .{timestamp});
//         // }

//         // if (product.remediationPath) |path| {
//         //     std.debug.print("remediationPath: {s}\n", .{path});
//         // }
//         i += 1;
//     }
// }

pub export fn getSecurityProducts() callconv(.C) [*]SecurityProduct {
    const providers = [_]security_center.WSC_SECURITY_PROVIDER{
        .ANTISPYWARE,
        .ANTIVIRUS,
        .FIREWALL,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var products_slice = allocator.alloc(SecurityProduct, providers.len) catch @panic("Allocation failed");

    const hr_init = com.CoInitializeEx(null, com.COINIT_APARTMENTTHREADED);
    if (hr_init != 0) {
        @panic("COM initialization failed");
    }
    defer com.CoUninitialize();

    for (providers, 0..) |provider, i| {
        products_slice[i] = getSecurityProduct(provider);
    }

    return products_slice.ptr;
}

fn getSecurityProduct(provider: security_center.WSC_SECURITY_PROVIDER) SecurityProduct {
    var product_list: ?*security_center.IWSCProductList = null;
    var product: ?*security_center.IWscProduct = null;

    var bstr_val: ?foundation.BSTR = null;

    const err = com.CoCreateInstance(security_center.CLSID_WSCProductList, null, com.CLSCTX_INPROC_SERVER, security_center.IID_IWSCProductList, @ptrCast(&product_list));
    std.debug.print("err is: {}\n", .{err});

    const prListErr = product_list.?.Initialize(provider);

    std.debug.print("prList err is: {}\n", .{prListErr});

    var product_count: i32 = 0;
    const countErr = product_list.?.get_Count(&product_count);

    std.debug.print("prList err is: {}\n", .{countErr});
    std.debug.print("count  is: {}\n", .{product_count});

    var securityProduct: SecurityProduct = undefined;
    securityProduct.ptype = getProductType(provider);

    std.debug.print("type is ---- {?} \n", .{securityProduct.ptype});

    var i: u32 = 0;
    while (i < @as(u32, @intCast(product_count))) : (i += 1) {
        const itemErr = product_list.?.get_Item(i, &product);
        std.debug.print("itemErr  is: {}\n", .{itemErr});

        const nameErr = product.?.get_ProductName(&bstr_val);
        securityProduct.name = toUtf8Slice(bstr_val.?);
        std.debug.print("nameERR  is: {}\n", .{nameErr});
        foundation.SysFreeString(bstr_val.?);
        bstr_val = null;

        var product_state: security_center.WSC_SECURITY_PRODUCT_STATE = undefined;
        const stateErr = product.?.get_ProductState(&product_state);
        securityProduct.state = getProductState(product_state);

        std.debug.print("stateErr  is: {}\n", .{stateErr});

        if (provider != security_center.WSC_SECURITY_PROVIDER_FIREWALL) {
            var signature_status: security_center.WSC_SECURITY_SIGNATURE_STATUS = undefined;
            const sigErr = product.?.get_SignatureStatus(&signature_status);

            std.debug.print("sigErr  is: {}\n", .{sigErr});
            securityProduct.signatureStatus = getSignatureStatus(signature_status);
        }

        const remediationPathErr = product.?.get_RemediationPath(&bstr_val);
        std.debug.print("remediationPathErr  is: {}\n", .{remediationPathErr});
        securityProduct.remediationPath = toUtf8Slice(bstr_val.?);
        foundation.SysFreeString(bstr_val.?);
        bstr_val = null;
        if (provider == security_center.WSC_SECURITY_PROVIDER_ANTIVIRUS) {
            const timeStampErr = product.?.get_ProductStateTimestamp(&bstr_val);
            std.debug.print("timeStamp(AntivirusONly)  is: {}\n", .{timeStampErr});
            securityProduct.timeStamp = toUtf8Slice(bstr_val.?);
            foundation.SysFreeString(bstr_val.?);
            bstr_val = null;
        }
        std.debug.print("reached here\n", .{});
    }
    return securityProduct;
}

fn toUtf8Slice(bstr_val: ?foundation.BSTR) [*]u16 {
    if (bstr_val == null) {
        return @as([*]u16, @constCast(&[_]u16{0}));
    }
    const len = foundation.SysStringLen(bstr_val);
    const slice = @as([*:0]u16, @ptrCast(bstr_val.?))[0..len];

    // std.debug.print("bstring value  {s}\n", .{std.unicode.utf16LeToUtf8Alloc(
    //     std.heap.page_allocator,
    //     slice.ptr,
    // ) catch "Unknown"});
    return slice.ptr;
}

fn getProductType(status: security_center.WSC_SECURITY_PROVIDER) i32 {
    return switch (status) {
        .ANTISPYWARE => 2,
        .FIREWALL => 1,
        .ANTIVIRUS => 0,
        else => -1,
    };
}

fn getSignatureStatus(status: security_center.WSC_SECURITY_SIGNATURE_STATUS) i32 {
    return switch (status) {
        .UP_TO_DATE => 1,
        .OUT_OF_DATE => 0,
    };
}

fn getProductState(state: security_center.WSC_SECURITY_PRODUCT_STATE) i32 {
    return switch (state) {
        .ON => 0,
        .OFF => 1,
        .SNOOZED => 2,
        .EXPIRED => 3,
    };
}
