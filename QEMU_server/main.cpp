#include <arpa/inet.h>
#include <cstring>
#include <format>
#include <iomanip>
#include <iostream>
#include <netinet/in.h>
#include <string>
#include <sys/socket.h>

int main() {
    sockaddr_in addr = {
        .sin_family = AF_INET,
        .sin_port = htons(31234),
        .sin_zero = 0
    };

    inet_aton("127.0.0.1", &addr.sin_addr);

    int fd = socket(AF_INET, SOCK_STREAM, 0);

    int opt = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    bind(fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr));

    listen(fd, 1);

    uint32_t latency_ms = 5;

    uint8_t latency_ms_be[4];
    latency_ms_be[0] = latency_ms >> 24;
    latency_ms_be[1] = latency_ms >> 16;
    latency_ms_be[2] = latency_ms >>  8;
    latency_ms_be[3] = latency_ms;

    while (true) {
        int client_fd = accept(fd, nullptr, nullptr);
        std::cout << std::format("---- New connection. Latency: {}ms ----", latency_ms) << std::endl;
        send(client_fd, latency_ms_be, sizeof(latency_ms_be), 0);

        char buffer[1024] = {};
        while (true) {
            ssize_t bytes = recv(client_fd, buffer, sizeof(buffer), 0);
            if (bytes < 0) {
                break;
            }

            std::string str(static_cast<size_t>(bytes), '\0');
            std::memcpy(str.data(), buffer, bytes);

            if (str.empty()) {
                break;
            }

            // for (const char ch: str) {
            //     std::cout << "0x" << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(ch) << ' ';
            // }
            // std::cout << std::endl;
        }
        std::cout << "---- Connection closed ----" << std::endl;
    }
}
