#include <dlfcn.h>
#include <binder/IBinder.h>

namespace android {

class IGraphicBufferProducer;

} // namespace

extern "C" {

void _ZN7android10BufferItemC1Ev(void* thisptr) {
    new (thisptr) android::LegacyBufferItem();
}

void _ZN7android10BufferItemD1Ev(void* thisptr) {
    static_cast<android::LegacyBufferItem*>(thisptr)->~LegacyBufferItem();
}

} // extern "C"
