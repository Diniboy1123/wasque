#define _GNU_SOURCE
#include <stdio.h>
#include <dlfcn.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <sys/socket.h>

int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
    static int (*original_bind)(int, const struct sockaddr *, socklen_t) = NULL;

    if (!original_bind) {
        original_bind = dlsym(RTLD_NEXT, "bind");
    }

    if (addr->sa_family == AF_INET) {
        struct sockaddr_in *in = (struct sockaddr_in *)addr;
        if (in->sin_addr.s_addr == inet_addr("127.0.0.1")) {
            in->sin_addr.s_addr = INADDR_ANY;  // 0.0.0.0
        }
    }

    return original_bind(sockfd, addr, addrlen);
}
