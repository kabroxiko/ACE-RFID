#include <nfc/nfc.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

int nfc_is_available(const char *conn_str) {
    nfc_context *context;
    nfc_init(&context);
    if (context == NULL) return 0;
    nfc_device *pnd = nfc_open(context, conn_str);
    if (pnd == NULL) {
        nfc_exit(context);
        return 0;
    }
    nfc_close(pnd);
    nfc_exit(context);
    return 1;
}

// Helper: convert hex string to byte array
static int hexstr_to_bytes(const char *hexstr, uint8_t *out, size_t maxlen) {
    size_t len = strlen(hexstr);
    size_t outpos = 0;
    for (size_t i = 0; i < len;) {
        while (isspace(hexstr[i])) i++;
        if (!isxdigit(hexstr[i])) break;
        char byte_str[3] = {0};
        byte_str[0] = hexstr[i++];
        if (i < len && isxdigit(hexstr[i])) byte_str[1] = hexstr[i++];
        else byte_str[1] = '0';
        out[outpos++] = (uint8_t)strtol(byte_str, NULL, 16);
        if (outpos >= maxlen) break;
        while (isspace(hexstr[i])) i++;
    }
    return (int)outpos;
}

// Write card content (Ultralight, pages 4-35)
int nfc_write_card_content(const char *conn_str, const char *hexstr) {
    nfc_context *context;
    nfc_device *pnd;
    nfc_target nt;
    nfc_init(&context);
    if (context == NULL) return -1;
    pnd = nfc_open(context, conn_str);
    if (pnd == NULL) {
        nfc_exit(context);
        return -2;
    }
    if (nfc_initiator_init(pnd) < 0) {
        nfc_close(pnd);
        nfc_exit(context);
        return -3;
    }
    const nfc_modulation nm = { .nmt = NMT_ISO14443A, .nbr = NBR_106 };
    if (nfc_initiator_select_passive_target(pnd, nm, NULL, 0, &nt) > 0) {
        uint8_t buf[128] = {0};
        int buflen = hexstr_to_bytes(hexstr, buf, sizeof(buf));
        int pagecount = (buflen < 128) ? buflen / 4 : 32;
        int status = 0;
        for (int page = 4; page < 4 + pagecount; page++) {
            uint8_t cmd[6] = {0xA2, page, buf[(page-4)*4], buf[(page-4)*4+1], buf[(page-4)*4+2], buf[(page-4)*4+3]};
            int res = nfc_initiator_transceive_bytes(pnd, cmd, 6, NULL, 0, 0);
            if (res < 0) {
                fprintf(stderr, "[ERROR] Write page %d failed: %s\n", page, nfc_strerror(pnd));
                status = -10;
            }
        }
        nfc_close(pnd);
        nfc_exit(context);
        return status;
    }
    nfc_close(pnd);
    nfc_exit(context);
    return -4;
}

int nfc_read_uid(const char *conn_str, char *uid_buf, size_t buf_len) {
    nfc_context *context;
    nfc_device *pnd;
    nfc_target nt;

    nfc_init(&context);
    if (context == NULL) return -1;

    pnd = nfc_open(context, conn_str);
    if (pnd == NULL) {
        nfc_exit(context);
        return -2;
    }

    if (nfc_initiator_init(pnd) < 0) {
        nfc_close(pnd);
        nfc_exit(context);
        return -3;
    }

    const nfc_modulation nm = { .nmt = NMT_ISO14443A, .nbr = NBR_106 };
    if (nfc_initiator_select_passive_target(pnd, nm, NULL, 0, &nt) > 0) {
        size_t uid_len = nt.nti.nai.szUidLen;
        if (uid_len > buf_len) uid_len = buf_len;
        memcpy(uid_buf, nt.nti.nai.abtUid, uid_len);
        nfc_close(pnd);
        nfc_exit(context);
        return (int)uid_len;
    }

    nfc_close(pnd);
    nfc_exit(context);
    return 0;
}

int nfc_get_firmware_version(const char *conn_str, char *buf, size_t buf_len) {
    nfc_context *context;
    nfc_device *pnd;
    nfc_init(&context);
    if (context == NULL) {
        return -1;
    }
    pnd = nfc_open(context, conn_str);
    if (pnd == NULL) {
        nfc_exit(context);
        return -2;
    }
    if (nfc_initiator_init(pnd) < 0) {
        nfc_close(pnd);
        nfc_exit(context);
        return -3;
    }
    char *info = NULL;
    int info_len = nfc_device_get_information_about(pnd, &info);
    printf("[DEBUG] nfc_device_get_information_about returned len=%d\n", info_len);
    if (info) {
        printf("[DEBUG] info string: %s\n", info);
        snprintf(buf, buf_len, "%s", info);
        nfc_free(info);
    } else {
        snprintf(buf, buf_len, "(firmware read error)");
    }
    nfc_close(pnd);
    nfc_exit(context);
    return 0;
}

// Reads the first 36 pages (Mifare Ultralight) and returns as hex string
int nfc_read_card_content(const char *conn_str, char *buf, size_t buf_len) {
    nfc_context *context;
    nfc_device *pnd;
    nfc_target nt;
    nfc_init(&context);
    if (context == NULL) return -1;
    pnd = nfc_open(context, conn_str);
    if (pnd == NULL) {
        nfc_exit(context);
        return -2;
    }
    if (nfc_initiator_init(pnd) < 0) {
        nfc_close(pnd);
        nfc_exit(context);
        return -3;
    }
    const nfc_modulation nm = { .nmt = NMT_ISO14443A, .nbr = NBR_106 };
    if (nfc_initiator_select_passive_target(pnd, nm, NULL, 0, &nt) > 0) {
        // Card type detection
        size_t out_len = 0;
        uint8_t atqa0 = nt.nti.nai.abtAtqa[0];
        uint8_t atqa1 = nt.nti.nai.abtAtqa[1];
        uint8_t sak = nt.nti.nai.btSak;
        // Mifare Classic: ATQA 0x00 0x04, SAK 0x08 or 0x28
        // Mifare Ultralight: ATQA 0x00 0x44, SAK 0x00
        if (atqa1 == 0x04 && (sak == 0x08 || sak == 0x28)) {
            // Mifare Classic 1K: 64 blocks, 16 bytes each
            out_len += snprintf(buf + out_len, buf_len - out_len, "Card type: Mifare Classic 1K\n");
            for (int block = 0; block < 64; block++) {
                uint8_t data[16];
                memset(data, 0, sizeof(data));
                int res = nfc_initiator_transceive_bytes(pnd, (const uint8_t[]){0x30, block}, 2, data, sizeof(data), 0);
                if (res < 0) {
                    fprintf(stderr, "[ERROR] Block %d read error: libnfc error code %d, command=[0x30, 0x%02X]\n", block, res, block);
                    fprintf(stderr, "[ERROR] libnfc: %s\n", nfc_strerror(pnd));
                    out_len += snprintf(buf + out_len, buf_len - out_len, "(block %d read error: code %d)\n", block, res);
                } else if (res > sizeof(data)) {
                    fprintf(stderr, "[ERROR] Buffer size too short for block %d: %d available, %d needed\n", block, (int)sizeof(data), res);
                    res = sizeof(data); // prevent overflow
                    out_len += snprintf(buf + out_len, buf_len - out_len, "(block %d buffer error)\n", block);
                } else if (res > 0) {
                    out_len += snprintf(buf + out_len, buf_len - out_len, "Block %02d: ", block);
                    for (int i = 0; i < res && out_len + 3 < buf_len; i++) {
                        out_len += snprintf(buf + out_len, buf_len - out_len, "%02X ", data[i]);
                    }
                    out_len += snprintf(buf + out_len, buf_len - out_len, "\n");
                } else {
                    out_len += snprintf(buf + out_len, buf_len - out_len, "(block %d read error)\n", block);
                }
            }
        } else if (atqa1 == 0x44 && sak == 0x00) {
            out_len += snprintf(buf + out_len, buf_len - out_len, "Card type: Mifare Ultralight\n");
            uint8_t rawbuf[32 * 4] = {0}; // pages 4-35, 32 pages, 4 bytes each
            int rawpos = 0;
            for (int page = 4; page < 36; page++) {
                uint8_t data[16] = {0};
                int res = nfc_initiator_transceive_bytes(pnd, (const uint8_t[]){0x30, page}, 2, data, sizeof(data), 0);
                if (res < 0) {
                    fprintf(stderr, "[ERROR] Page %d read error: libnfc error code %d, command=[0x30, 0x%02X]\n", page, res, page);
                    fprintf(stderr, "[ERROR] libnfc: %s\n", nfc_strerror(pnd));
                    // Fill with 0x00 on error
                    for (int i = 0; i < 4 && rawpos < sizeof(rawbuf); i++) rawbuf[rawpos++] = 0x00;
                    out_len += snprintf(buf + out_len, buf_len - out_len, "(page %d read error: code %d)\n", page, res);
                } else {
                    for (int i = 0; i < 4 && i < res && rawpos < sizeof(rawbuf); i++) rawbuf[rawpos++] = data[i];
                }
            }
            // Output rawbuf as hex string
            out_len += snprintf(buf + out_len, buf_len - out_len, "Raw Data: ");
            for (int i = 0; i < sizeof(rawbuf) && out_len + 3 < buf_len; i++) {
                out_len += snprintf(buf + out_len, buf_len - out_len, "%02X ", rawbuf[i]);
            }
            out_len += snprintf(buf + out_len, buf_len - out_len, "\n");
        } else {
            out_len += snprintf(buf + out_len, buf_len - out_len, "Unknown card type (ATQA %02X %02X, SAK %02X)\n", atqa0, atqa1, sak);
        }
        nfc_close(pnd);
        nfc_exit(context);
        return (int)out_len;
    }
    nfc_close(pnd);
    nfc_exit(context);
    return 0;
}
