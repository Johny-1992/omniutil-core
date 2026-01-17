#include "wallet.h"
#include "protocol.h"

int main() {
    omni_init();
    while(1) {
        handle_apdu();
    }
    return 0;
}
