
// original code written by Cameron Rich (2007, project axTLS)
// see original copyright and license in crypto.readme

#ifndef _AES_H
#define _AES_H

#ifdef __cplusplus
extern "C" {
#endif

    
#include <stdint.h>

#define AES_MAXROUNDS			14
#define AES_BLOCKSIZE           16
#define AES_IV_SIZE             16

typedef struct aes_key_st 
{
    uint16_t rounds;
    uint16_t key_size;
    uint32_t ks[(AES_MAXROUNDS+1)*8];
    uint8_t iv[AES_IV_SIZE];
} AES_CTX;

typedef enum
{
    AES_MODE_128,
    AES_MODE_256
} AES_MODE;

void AES_set_key(AES_CTX *ctx, const uint8_t *key, 
        const uint8_t *iv, AES_MODE mode);
void AES_cbc_encrypt(AES_CTX *ctx, const uint8_t *msg, 
        uint8_t *out, int length);
void AES_cbc_decrypt(AES_CTX *ks, const uint8_t *in, uint8_t *out, int length);
void AES_convert_key(AES_CTX *ctx);

#ifdef __cplusplus
}
#endif


#endif  /*_AES_H*/

