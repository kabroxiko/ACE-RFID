#ifndef NFCWrapper_h
#define NFCWrapper_h

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

int nfc_is_available(const char *conn_str);
int nfc_read_uid(const char *conn_str, unsigned char *uid_buf, size_t buf_len);
int nfc_get_firmware_version(const char *conn_str, char *buf, size_t buf_len);
int nfc_read_card_content(const char *conn_str, char *buf, size_t buf_len);
int nfc_write_card_content(const char *conn_str, const char *hexstr);

#ifdef __cplusplus
}
#endif

#endif /* NFCWrapper_h */
