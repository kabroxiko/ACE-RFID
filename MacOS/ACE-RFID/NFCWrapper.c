#include "NFCWrapper.h"
#include <nfc/nfc.h>

int nfc_is_available(void) {
    nfc_context *context;
    nfc_init(&context);
    if (context == NULL) return 0;
    nfc_device *pnd = nfc_open(context, NULL);
    if (pnd == NULL) {
        nfc_exit(context);
        return 0;
    }
    nfc_close(pnd);
    nfc_exit(context);
    return 1;
}
