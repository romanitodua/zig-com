// const zigwin32 = @import("zigwin32");
// const std = @import("std");
// const lib = @import("myzigprojects_lib");

// const security_center = zigwin32.system.security_center;
// const com = zigwin32.system.com;
// const foundation = zigwin32.foundation;
// const types = @import("mysecurity.zig");

// pub export fn getSecurityProducts(provider: security_center.WSC_SECURITY_PROVIDER) callconv(.C) [*]types.SecurityProduct {
//     const hr_init = com.CoInitializeEx(null, com.COINIT_APARTMENTTHREADED);
//     std.debug.print("The number is: {}\n", .{hr_init});
//     defer com.CoUninitialize();

//     var product_list: ?*security_center.IWSCProductList = null;
//     var product: ?*security_center.IWscProduct = null;

//     var bstr_val: ?foundation.BSTR = null;

//     const err = com.CoCreateInstance(security_center.CLSID_WSCProductList, null, com.CLSCTX_INPROC_SERVER, security_center.IID_IWSCProductList, @ptrCast(&product_list));
//     std.debug.print("err is: {}\n", .{err});

//     const prListErr = product_list.?.Initialize(provider);

//     std.debug.print("prList err is: {}\n", .{prListErr});

//     var product_count: i32 = 0;
//     const countErr = product_list.?.get_Count(&product_count);

//     const products = @as(
//         [*]types.SecurityProduct,
//         @ptrCast(std.c.malloc(@sizeOf(types.SecurityProduct) * @as(usize, @intCast(product_count)))),
//     );

//     std.debug.print("prList err is: {}\n", .{countErr});
//     std.debug.print("count  is: {}\n", .{product_count});

//     var i: u32 = 0;
//     while (i < @as(u32, @intCast(product_count))) : (i += 1) {
//         products[i] = types.SecurityProduct{
//             .type = types.ProductType.fromWSC(provider),
//             .name = null,
//             .state = undefined,
//             .signatureStatus = null,
//             .remediationPath = null,
//             .timeStamp = null,
//         };
//         products[i].type = types.ProductType.fromWSC(provider);
//         const itemErr = product_list.?.get_Item(i, &product);
//         std.debug.print("itemErr  is: {}\n", .{itemErr});

//         const nameErr = product.?.get_ProductName(&bstr_val);
//         products[i].name = toUtf8Slice(bstr_val.?);
//         std.debug.print("nameERR  is: {}\n", .{nameErr});
//         foundation.SysFreeString(bstr_val.?);
//         bstr_val = null;

//         var product_state: security_center.WSC_SECURITY_PRODUCT_STATE = undefined;
//         const stateErr = product.?.get_ProductState(&product_state);
//         products[i].state = types.ProductState.fromWSC(product_state);

//         std.debug.print("stateErr  is: {}\n", .{stateErr});

//         if (provider != security_center.WSC_SECURITY_PROVIDER_FIREWALL) {
//             var signature_status: security_center.WSC_SECURITY_SIGNATURE_STATUS = undefined;
//             const sigErr = product.?.get_SignatureStatus(&signature_status);

//             std.debug.print("sigErr  is: {}\n", .{sigErr});
//             products[i].signatureStatus = types.SignatureStatus.fromWSC(signature_status);
//         }

//         const remediationPathErr = product.?.get_RemediationPath(&bstr_val);
//         std.debug.print("remediationPathErr  is: {}\n", .{remediationPathErr});
//         products[i].remediationPath = toUtf8Slice(bstr_val.?);
//         foundation.SysFreeString(bstr_val.?);
//         bstr_val = null;

//         if (provider == security_center.WSC_SECURITY_PROVIDER_ANTIVIRUS) {
//             const timeStampErr = product.?.get_ProductStateTimestamp(&bstr_val);
//             std.debug.print("timeStamp(AntivirusONly)  is: {}\n", .{timeStampErr});
//             products[i].timeStamp = toUtf8Slice(bstr_val.?);
//             foundation.SysFreeString(bstr_val);
//             bstr_val = null;
//         }
//     }
//     return products;
// }

// fn toUtf8Slice(bstr_val: ?foundation.BSTR) [*]u8 {
//     const len = foundation.SysStringLen(bstr_val.?);
//     const utf8Slice = @as([*]u8, @ptrCast(bstr_val.?))[0..len];
//     return utf8Slice.ptr;
// }

// // pub export fn freeSecurityProducts(products: [*]types.SecurityProduct, count: u32) callconv(.C) void {
// //     var i: u32 = 0;
// //     while (i < count) : (i += 1) {
// //         if (products[i].name) |name| {
// //             std.c.free(@as(*anyopaque, @ptrCast(name)));
// //         }
// //         if (products[i].remediationPath) |path| {
// //             std.c.free(@as(*anyopaque, @ptrCast(path)));
// //         }
// //         if (products[i].timeStamp) |ts| {
// //             std.c.free(@as(*anyopaque, @ptrCast(ts)));
// //         }
// //     }
// //     std.c.free(@as(*anyopaque, @ptrCast(products)));
// // }
