package main

/*
#cgo LDFLAGS: -L. -lmyzigprojects
#include <stdint.h>

typedef struct {
    int32_t ptype;
    uint16_t* name;
    int32_t state;
    int32_t signatureStatus;
    uint16_t* timeStamp;
    uint16_t* remediationPath;
} SecurityProduct;

extern SecurityProduct* getSecurityProducts(void);
*/
import "C"
import (
	"fmt"
	"unicode/utf16"
	"unsafe"
)

func utf16PtrToString(ptr *C.uint16_t) string {
	if ptr == nil {
		return ""
	}

	var units []uint16
	for i := 0; ; i++ {
		unit := *(*uint16)(unsafe.Add(unsafe.Pointer(ptr), i*2))
		if unit == 0 {
			break
		}
		units = append(units, unit)
	}

	return string(utf16.Decode(units))
}

func main() {
	persons := C.getSecurityProducts()
	personsSlice := unsafe.Slice(persons, 3)

	for _, p := range personsSlice {
		firstName := utf16PtrToString(p.name)
		fmt.Println("name is", firstName)
	}
}
